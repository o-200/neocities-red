# frozen_string_literal: true

require "pathname"
require "tty/table"
require "tty/prompt"
require "fileutils"
require "json"
require "thor"
require_relative "cli_display"

module NeocitiesRed
  # Thor-based command-line interface for the NeocitiesRed gem.
  #
  # Provides subcommands for managing a Neocities site: push, upload,
  # delete, diff, list, info, pull, purge, logout, and pizza.
  #
  # Authentication is handled lazily — the first command that requires
  # an API connection will prompt for credentials (or read from config/env).
  #
  # @example Running from shell
  #   $ neocities-red push .
  #   $ neocities-red list -a
  #   $ neocities-red diff --ignore-dotfiles
  #
  # @see NeocitiesRed::Client Underlying API client
  # @see NeocitiesRed::CliDisplay Terminal output helper
  class CLI < Thor
    package_name "neocities-red"
    default_task :help
    map %w[-h --help] => :help
    map %w[-v --version] => :version

    class_option :api_key,
                 type: :string,
                 desc: "Use a specific API key instead of reading from env/config"

    desc "diff [PATH]", "Compare local files with remote and show differences"
    method_option :help, aliases: "-h", type: :boolean
    method_option :ignore_dotfiles, type: :boolean, default: false
    method_option :exclude, aliases: "-e", type: :string, repeatable: true, default: []

    # Compares local files with the remote Neocities site and displays
    # added, modified, and removed files.
    #
    # @param path [String] local directory path to compare (defaults to current directory)
    # @return [void]
    def diff(path = ".")
      return display_help_for("diff") if help_requested?(options[:help], path)

      client = ensure_client!
      exclude = Services::Common::Exclusions.build(Array(options[:exclude]), base_path: path)

      added, modified, removed = Services::Site::Differencer.new(
        client,
        path: path,
        detail: false,
        ignore_dotfiles: options[:ignore_dotfiles],
        exclude: exclude
      ).show

      display.display_diff_results(added: added, modified: modified, removed: removed)
    end

    desc "delete PATH [PATH ...]", "Delete files on your Neocities site"
    method_option :help, aliases: "-h", type: :boolean

    # Deletes one or more files from the remote Neocities site.
    #
    # @param paths [Array<String>] remote file paths to delete
    # @return [void]
    def delete(*paths)
      return display_help_for("delete") if paths.empty? || help_requested?(options[:help], paths)

      client = ensure_client!
      paths.each { |path| Services::File::Remover.new(client, path, display: display).remove }
    end

    desc "logout", "Remove the site api key from the config"
    method_option :help, aliases: "-h", type: :boolean
    method_option :yes, aliases: "-y", type: :boolean, default: false

    # Removes the stored API key from the local config file.
    #
    # Requires the +--yes+ / +-y+ flag to confirm the action.
    #
    # @return [void]
    def logout
      return display_help_for("logout") if help_requested?(options[:help]) || !options[:yes]

      FileUtils.rm_f(app_config_path)
      display.display_logout_success
    end

    desc "info [SITENAME]", "Get site info"
    method_option :help, aliases: "-h", type: :boolean

    # Displays information and statistics for a Neocities site.
    #
    # @param sitename [String, nil] site name to query; defaults to the
    #   currently authenticated site when omitted
    # @return [void]
    # @raise [NeocitiesRed::APIError] if the API request fails
    def info(sitename = nil)
      return display_help_for("info") if help_requested?(options[:help], sitename)

      client = ensure_client!
      profile_info = Services::Site::Informer.new(client, [sitename].compact, @sitename).pretty_print
      display.say TTY::Table.new(profile_info)
    rescue StandardError => e
      display.display_response(e)
    end

    desc "list [PATH]", "List files on your Neocities site"
    method_option :help, aliases: "-h", type: :boolean
    method_option :detail, aliases: "-d", type: :boolean, default: false
    method_option :all, aliases: "-a", type: :boolean, default: false

    # Lists files on the remote Neocities site.
    #
    # @param path [String, nil] remote directory path to list (nil for root,
    #   or when +--all+ is used)
    # @return [void]
    # @raise [NeocitiesRed::APIError] if the API request fails
    def list(path = nil)
      if help_requested?(options[:help], path) || (path.nil? && options[:all].nil? && options[:detail].nil?)
        display_help_for("list")
        return
      end

      client = ensure_client!
      path = nil if options[:all]
      display.say Services::File::List.new(client, path, options[:detail], display: display).show
    rescue NeocitiesRed::APIError => e
      display.display_response(e)
    end

    desc "push PATH", "Recursively upload a local directory to your Neocities site"
    method_option :help, aliases: "-h", type: :boolean
    method_option :no_gitignore, type: :boolean, default: false
    method_option :ignore_dotfiles, type: :boolean, default: false
    method_option :exclude, aliases: "-e", type: :string, repeatable: true, default: []
    method_option :dry_run, type: :boolean, default: false
    method_option :prune, type: :boolean, default: false
    method_option :optimized, type: :boolean, default: false

    # Recursively uploads a local directory to the Neocities site.
    #
    # Supports +--no-gitignore+ to ignore .gitignore rules,
    # +--ignore-dotfiles+ to skip dot-prefixed files,
    # +--exclude+ to skip specific paths, +--dry-run+ to preview changes,
    # +--prune+ to delete remote files not present locally, and
    # +--optimized+ to skip files whose SHA1 hash matches the server.
    #
    # @param root [String, nil] local directory path to upload
    # @return [void]
    # @raise [ArgumentError] if the path does not exist or is not a directory
    def push(root = nil)
      return display_help_for("push") if help_requested?(options[:help], root)

      client = ensure_client!
      return display_help_for("push") if root.nil?

      Services::Site::Pusher.new(
        client,
        display,
        root: root,
        no_gitignore: options[:no_gitignore],
        ignore_dotfiles: options[:ignore_dotfiles],
        exclude: Array(options[:exclude]),
        dry_run: options[:dry_run],
        prune: options[:prune],
        optimized: options[:optimized]
      ).push
    rescue ArgumentError => e
      display.display_response(result: "error", message: e.message)
      display_help_for("push")
    end

    desc "upload LOCAL_PATH [REMOTE_PATH]", "Upload a file/folder to your Neocities site"
    method_option :help, aliases: "-h", type: :boolean

    # Uploads a single file or an entire folder to the Neocities site.
    #
    # When +LOCAL_PATH+ is a file, uploads it directly.
    # When it is a directory, uploads all files within it in parallel.
    #
    # @param local_path [String, nil] local file or directory path
    # @param remote_path [String, nil] remote destination; defaults to the basename of +local_path+
    # @return [void]
    def upload(local_path = nil, remote_path = nil)
      return display_help_for("upload") if help_requested?(options[:help], [local_path, remote_path])
      return display_help_for("upload") if local_path.nil?

      client = ensure_client!
      dest = remote_path || File.basename(local_path)
      if File.file?(local_path)
        Services::File::Uploader.new(client, local_path, dest, display: display).upload
      elsif File.directory?(local_path)
        folder_uploader = Services::File::FolderUploader.new(client, local_path, dest, display: display)
        files_list = folder_uploader.files
        folder_uploader.upload(files_list)
      end
    end

    desc "pull", "Get the most recent version of files from your site"
    method_option :help, aliases: "-h", type: :boolean
    method_option :quiet, aliases: "-q", type: :boolean, default: false

    # Downloads the latest version of site files from the remote Neocities site.
    #
    # Skips files that haven't changed since the last pull (based on stored
    # timestamp and working directory). Use +--quiet+ to suppress per-file
    # output and show a spinner instead.
    #
    # @return [void]
    # @raise [StandardError] on network or API errors
    def pull
      return display_help_for("pull") if help_requested?(options[:help])

      client = ensure_client!
      data = read_config || {}

      last_pull_time = data.dig("LAST_PULL", "time")
      last_pull_loc = data.dig("LAST_PULL", "loc")

      Services::Site::Exporter.new(client, @sitename, data, app_config_path, display: display)
                              .export(quiet: options[:quiet], last_pull_time: last_pull_time, last_pull_loc: last_pull_loc)
    rescue StandardError => e
      display.display_response(e)
    end

    desc "purge", "Delete everything from your site (development only)"
    method_option :yes, aliases: "-y", type: :boolean, default: false
    method_option :dry_run, type: :boolean, default: false

    # Deletes all files from the Neocities site.
    #
    # Requires the +--yes+ / +-y+ flag to confirm the destructive action.
    # Use +--dry-run+ to preview what would be deleted without changes.
    #
    # @return [void]
    def purge
      return display_help_for("purge") unless options[:yes]

      client = ensure_client!
      display.display_dry_run_notice if options[:dry_run]
      resp = client.list
      deleted_dirs = []
      resp[:files].sort_by { |f| f[:is_directory] ? 0 : 1 }.each do |file|
        next if deleted_dirs.any? { |dir| file[:path].start_with?(dir) }

        display.display_delete_progress(file[:path])
        delete_resp = client.delete_wrapper_with_dry_run(file[:path], dry_run: options[:dry_run])

        if delete_resp[:result] == "success"
          deleted_dirs << file[:path] if file[:is_directory]
          display.display_delete_success
        else
          display.display_delete_error(delete_resp)
        end
      end
    end

    desc "pizza", "Order a free pizza"

    # Easter egg — displays a humorous pizza-related excuse.
    #
    # @return [void]
    def pizza
      display_help_for(__method__)
    end

    # Returns the platform-specific application config directory path.
    #
    # @param name [String] application name (e.g. "neocities")
    # @return [String, nil] full path to the config directory, or nil if
    #   the platform cannot be determined
    def self.app_config_path(name)
      platform = case RUBY_PLATFORM
                 when /cygwin|mswin|mingw|bccwin|wince|emx|win32/
                   :windows
                 when /darwin/
                   :darwin
                 when /linux/
                   :linux
                 when /freebsd/
                   :freebsd
                 else
                   :unknown
                 end

      case platform
      when :linux
        return File.join(ENV["XDG_CONFIG_HOME"], name) if ENV["XDG_CONFIG_HOME"]
        return File.join(Dir.home, ".config", name) if Dir.home
      when :darwin
        return File.join(Dir.home, "Library", "Application Support", name) if Dir.home
      when :windows
        return File.join(ENV["LOCALAPPDATA"], name) if ENV["LOCALAPPDATA"]

        if ENV["USERPROFILE"]
          return File.join(
            ENV["USERPROFILE"],
            "AppData",
            "Local",
            name
          )
        end
      else
        # FreeBSD and other unknown UNIX-like systems use dotfile directly in home directory
        return File.join(Dir.home, ".#{name}") if Dir.home
      end

      nil
    end

    desc "help [COMMAND]", "Show help for a command"

    # Displays help for a specific command or the general help screen.
    #
    # @param command [String, nil] command name to show help for;
    #   nil displays the main help screen
    # @return [void]
    def help(command = nil)
      return display.display_help_and_exit if command.nil?

      custom_help_method = "display_#{command}_help_and_exit"
      return display.public_send(custom_help_method) if display.respond_to?(custom_help_method)

      super
    end

    desc "version", "Display neocities-red version"

    # Prints the current gem version to stdout.
    #
    # @return [void]
    def version
      display.say NeocitiesRed::VERSION
    end

    no_commands do
      alias_method :display_help_for, :help

      # Returns the initialized {CliDisplay} instance.
      #
      # @return [NeocitiesRed::CliDisplay]
      def display
        @display ||= NeocitiesRed::CliDisplay.new
      end

      # Returns the initialized TTY::Prompt instance for interactive input.
      #
      # @return [TTY::Prompt]
      def prompt
        @prompt ||= TTY::Prompt.new
      end

      # Returns the full path to the application config file.
      #
      # @return [String] path to +config.json+ inside the platform config directory
      def app_config_path
        @app_config_path ||= File.join(self.class.app_config_path("neocities"), "config.json")
      end

      # Reads and parses the JSON config file from disk.
      #
      # @return [Hash, nil] parsed config hash, or nil if the file does not exist
      def read_config
        file = File.read(app_config_path)
        JSON.parse(file)
      rescue Errno::ENOENT
        nil
      end

      # Lazily initializes and returns an authenticated {Client} instance.
      #
      # Reads the API key from (in order): CLI option, environment variable,
      # or stored config. If no key is found, triggers interactive login.
      #
      # @return [NeocitiesRed::Client]
      def ensure_client!
        return @client if @client

        config = read_config
        @sitename = config && config["SITENAME"]

        @api_key = options[:api_key] || ENV.fetch("NEOCITIES_API_KEY", nil)
        @api_key ||= config && config["API_KEY"]&.strip

        if @api_key.nil? || @api_key.empty?
          authenticate_and_persist_key!
        else
          @client = NeocitiesRed::Client.new(api_key: @api_key)
        end

        @client
      end

      # Prompts the user for credentials, obtains an API key, and stores it.
      #
      # Saves the API key and sitename to the local config file with
      # restricted permissions (0600).
      #
      # @return [void]
      # @raise [Thor::Error] if the API key cannot be obtained
      def authenticate_and_persist_key!
        display.display_login_prompt

        @sitename ||= prompt.ask("sitename/username:", default: ENV.fetch("NEOCITIES_SITENAME", nil))
        password = prompt.mask("password:", default: ENV.fetch("NEOCITIES_PASSWORD", nil))

        temp_client = NeocitiesRed::Client.new(sitename: @sitename, password: password)
        resp = temp_client.key

        unless resp[:api_key]
          display.display_response(resp)
          raise Thor::Error, "failed to obtain API key"
        end

        @api_key = resp[:api_key]
        conf = {
          API_KEY: @api_key,
          SITENAME: @sitename
        }

        FileUtils.mkdir_p(Pathname(app_config_path).dirname)
        persist_config(conf)
        display.display_api_key_saved(@sitename, app_config_path)
        @client = NeocitiesRed::Client.new(api_key: @api_key)
      end

      # Writes the config hash to disk as JSON and restricts file permissions.
      #
      # @param conf [Hash] configuration data to persist
      # @return [void]
      def persist_config(conf)
        File.write(app_config_path, conf.to_json)
        FileUtils.chmod(0o600, app_config_path)
      end

      # Checks if the given value contains a help flag.
      #
      # @param value [String, Array<String>, nil] value to inspect
      # @return [Boolean] true if the value is or contains "-h", "--help", or "help"
      def help_requested_for?(value)
        case value
        when Array
          value.intersect?(["-h", "--help", "help"])
        else
          ["-h", "--help", "help"].include?(value)
        end
      end

      # Determines if help was requested via the +--help+ option or the value.
      #
      # @param help_option [Boolean, nil] the Thor +--help+ option value
      # @param value [String, Array<String>, nil] the positional argument to check
      # @return [Boolean]
      def help_requested?(help_option, value = nil)
        help_option || (value && help_requested_for?(value))
      end
    end
  end
end
