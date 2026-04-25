# frozen_string_literal: true

require "pathname"
require "tty/table"
require "tty/prompt"
require "fileutils"
require "json"
require "thor"
require_relative "cli_display"

module NeocitiesRed
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
    def diff(path = ".")
      return display_help_for("diff") if help_requested?(options[:help], path)

      client = ensure_client!
      exclude = build_diff_exclusions(path, Array(options[:exclude]))

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
    def delete(*paths)
      return display_help_for("delete") if paths.empty? || help_requested?(options[:help], paths)

      client = ensure_client!
      paths.each { |path| Services::File::Remover.new(client, path).remove }
    end

    desc "logout", "Remove the site api key from the config"
    method_option :help, aliases: "-h", type: :boolean
    method_option :yes, aliases: "-y", type: :boolean, default: false
    def logout
      return display_help_for("logout") if help_requested?(options[:help]) || !options[:yes]

      FileUtils.rm_f(app_config_path)
      display.display_logout_success
    end

    desc "info [SITENAME]", "Get site info"
    method_option :help, aliases: "-h", type: :boolean
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
    def list(path = nil)
      if help_requested?(options[:help], path) || (path.nil? && options[:all].nil? && options[:detail].nil?)
        display_help_for("list")
        return
      end

      client = ensure_client!
      path = nil if options[:all]
      display.say Services::File::List.new(client, path, options[:detail]).show
    end

    desc "push PATH", "Recursively upload a local directory to your Neocities site"
    method_option :help, aliases: "-h", type: :boolean
    method_option :no_gitignore, type: :boolean, default: false
    method_option :ignore_dotfiles, type: :boolean, default: false
    method_option :exclude, aliases: "-e", type: :string, repeatable: true, default: []
    method_option :dry_run, type: :boolean, default: false
    method_option :prune, type: :boolean, default: false
    method_option :optimized, type: :boolean, default: false
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

    desc "upload LOCAL_PATH REMOTE_PATH", "Upload a file/folder to your Neocities site"
    method_option :help, aliases: "-h", type: :boolean
    def upload(local_path = nil, remote_path = nil)
      return display_help_for("upload") if help_requested?(options[:help], [local_path, remote_path])
      return display_help_for("upload") if local_path.nil? || remote_path.nil?

      client = ensure_client!
      if File.file?(local_path)
        Services::File::Uploader.new(client, local_path, remote_path).upload
      elsif File.directory?(local_path)
        folder_uploader = Services::File::FolderUploader.new(client, local_path, remote_path)
        files_list = folder_uploader.files
        folder_uploader.upload(files_list)
      end
    end

    desc "pull", "Get the most recent version of files from your site"
    method_option :help, aliases: "-h", type: :boolean
    method_option :quiet, aliases: "-q", type: :boolean, default: false
    def pull
      return display_help_for("pull") if help_requested?(options[:help])

      client = ensure_client!
      data = read_config || {}

      last_pull_time = data.dig("LAST_PULL", "time")
      last_pull_loc = data.dig("LAST_PULL", "loc")

      Services::Site::Exporter.new(client, @sitename, data, app_config_path)
                              .export(quiet: options[:quiet], last_pull_time: last_pull_time, last_pull_loc: last_pull_loc)
    end

    desc "purge", "Delete everything from your site (development only)"
    method_option :yes, aliases: "-y", type: :boolean, default: false
    def purge
      return display_help_for("purge") unless options[:yes]

      client = ensure_client!
      resp = client.list
      resp[:files].each do |file|
        display.display_delete_progress(file[:path])
        delete_resp = client.delete_wrapper_with_dry_run(file[:path], dry_run: options[:dry_run])

        if delete_resp[:result] == "success"
          display.display_delete_success
        else
          display.display_delete_error(delete_resp)
        end
      end
    end

    desc "pizza", "Order a free pizza"
    def pizza
      display_help_for(__method__)
    end

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
    def help(command = nil)
      return display.display_help_and_exit if command.nil?

      custom_help_method = "display_#{command}_help_and_exit"
      return display.public_send(custom_help_method) if display.respond_to?(custom_help_method)

      super
    end

    desc "version", "Display neocities-red version"
    def version
      display.say NeocitiesRed::VERSION
    end

    no_commands do
      alias_method :display_help_for, :help

      def display
        @display ||= NeocitiesRed::CliDisplay.new
      end

      def prompt
        @prompt ||= TTY::Prompt.new
      end

      def app_config_path
        @app_config_path ||= File.join(self.class.app_config_path("neocities"), "config.json")
      end

      def read_config
        file = File.read(app_config_path)
        JSON.parse(file)
      rescue Errno::ENOENT
        nil
      end

      def ensure_client!
        return @client if @client

        config = read_config
        @sitename = config && config["SITENAME"]
        @last_pull = config && config["LAST_PULL"]

        @api_key = options[:api_key] || ENV.fetch("NEOCITIES_API_KEY", nil)
        @api_key ||= config && config["API_KEY"]&.strip

        if @api_key.nil? || @api_key.empty?
          authenticate_and_persist_key!
        else
          @client = NeocitiesRed::Client.new(api_key: @api_key)
        end

        @client
      end

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
        File.write(app_config_path, conf.to_json)
        display.display_api_key_saved(@sitename, app_config_path)
        @client = NeocitiesRed::Client.new(api_key: @api_key)
      end

      def build_diff_exclusions(base_path, excluded_entries)
        base = Pathname.new(base_path).expand_path
        excludes = []

        excluded_entries.each do |entry|
          target = Pathname.new(entry).expand_path
          next unless target.exist?

          filepath = target.relative_path_from(base).to_s

          if File.file?(target)
            excludes << filepath
          elsif File.directory?(target)
            excludes.concat(
              Dir.glob(File.join(target, "**", "*"), File::FNM_DOTMATCH).map do |path|
                Pathname.new(path).expand_path.relative_path_from(base).to_s
              end
            )
            excludes << filepath
          end
        end

        excludes
      end

      def help_requested_for?(value)
        case value
        when Array
          value.any? { |item| ["-h", "--help", "help"].include?(item) }
        else
          ["-h", "--help", "help"].include?(value)
        end
      end

      def help_requested?(help_option, value = nil)
        help_option || (value && help_requested_for?(value))
      end
    end
  end
end
