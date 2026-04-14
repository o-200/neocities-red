# frozen_string_literal: true

require "pathname"
require "tty/table"
require "tty/prompt"
require "fileutils"
require "json"
require "whirly"
require "digest"
require "time"
require_relative "cli_display"

# warning - the big quantity of working threads could be considered like-a DDOS.
# Your ip-address could get banned for a few days.
MAX_THREADS = 5

module NeocitiesRed
  class CLI
    SUBCOMMANDS = %w[upload delete list info push logout pizza pull purge diff].freeze
    HELP_SUBCOMMANDS = ["-h", "--help", "help"].freeze

    def initialize(argv)
      @argv = argv.dup
      @display = NeocitiesRed::CliDisplay.new
      @subcmd = @argv.first
      @subargs = @argv[1..@argv.length]
      @prompt = TTY::Prompt.new
      @api_key = ENV["NEOCITIES_API_KEY"] || nil
      @app_config_path = File.join self.class.app_config_path("neocities"), "config.json"
    end

    def run
      if @argv[0] == "version"
        @display.say NeocitiesRed::VERSION
        exit
      end

      if HELP_SUBCOMMANDS.include?(@subcmd) && SUBCOMMANDS.include?(@subargs[0])
        @display.public_send("display_#{@subargs[0]}_help_and_exit")
      elsif @subcmd.nil? || !SUBCOMMANDS.include?(@subcmd)
        @display.display_help_and_exit
      elsif @subargs.join.match(HELP_SUBCOMMANDS.join("|")) && @subcmd != "info"
        @display.public_send("display_#{@subcmd}_help_and_exit")

      end

      unless @api_key
        begin
          file = File.read @app_config_path
          data = JSON.parse file

          if data
            @api_key = data["API_KEY"].strip
            @sitename = data["SITENAME"]
            @last_pull = data["LAST_PULL"] # Store the last time a pull was performed so that we only fetch from updated files
          end
        rescue Errno::ENOENT
          @api_key = nil
        end
      end

      if @api_key.nil?
        @display.display_login_prompt

        if !@sitename && !@password
          @sitename = @prompt.ask("sitename:", default: ENV.fetch("NEOCITIES_SITENAME", nil))
          @password = @prompt.mask("password:", default: ENV.fetch("NEOCITIES_PASSWORD", nil))
        end

        @client = NeocitiesRed::Client.new sitename: @sitename, password: @password

        resp = @client.key
        if resp[:api_key]
          conf = {
            API_KEY: resp[:api_key],
            SITENAME: @sitename
          }

          FileUtils.mkdir_p Pathname(@app_config_path).dirname
          File.write @app_config_path, conf.to_json

          @display.display_api_key_saved(@sitename, @app_config_path)
        else
          @display.display_response(resp)
          exit
        end
      else
        @client = NeocitiesRed::Client.new api_key: @api_key
      end

      send @subcmd
    end

    def diff
      @display.display_diff_help_and_exit if @subargs.empty?

      @ignore_dotfiles = false
      @path = "."
      @exclude = []

      loop do
        arg = @subargs[0]
        break if arg.nil?

        if arg == "--ignore-dotfiles"
          @subargs.shift
          @ignore_dotfiles = true

        elsif arg == "-e"
          @subargs.shift

          base = Pathname.new(@path).expand_path
          target = Pathname.new(@subargs[0]).expand_path
          filepath = target.relative_path_from(base).to_s

          if File.file?(target)
            @exclude << filepath
          elsif File.directory?(target)
            @exclude += Dir.glob(
              File.join(target, "**", "*"),
              File::FNM_DOTMATCH
            ).map do |path|
              Pathname.new(path).expand_path.relative_path_from(base).to_s
            end

            @exclude << filepath
          end

          @subargs.shift

        elsif File.directory?(arg)
          @path = arg
          @subargs.shift
        end
      end

      added, modified, removed = Services::SiteDifference.new(
        @client,
        path: @path,
        detail: false,
        ignore_dotfiles: @ignore_dotfiles,
        exclude: @exclude
      ).show

      @display.display_diff_results(added: added, modified: modified, removed: removed)
    end

    def delete
      @display.display_delete_help_and_exit if @subargs.empty?

      @subargs.each do |path|
        Services::FileRemover.new(@client, path).remove
      end
    end

    def logout
      confirmed = false

      loop do
        case @subargs[0]
        when "-y"
          @subargs.shift
          confirmed = true
        when /^-/
          @display.display_unknown_option(@subargs[0])
          break
        else
          break
        end
      end

      if confirmed
        FileUtils.rm @app_config_path
        @display.display_logout_success
      else
        @display.display_logout_help_and_exit
      end
    end

    def info
      profile_info = Services::ProfileInfo.new(@client, @subargs, @sitename).pretty_print
      @display.say TTY::Table.new(profile_info)
    rescue StandardError => e
      @display.display_response(e)
    end

    def list
      @display.display_list_help_and_exit if @subargs.empty?

      @detail = true if @subargs.delete("-d") == "-d"

      @subargs[0] = nil if @subargs.delete("-a")

      path = @subargs[0]

      @display.say Services::FileList.new(@client, path, @detail).show
    end

    def push
      @display.display_push_help_and_exit if @subargs.empty?
      @no_gitignore = false
      @ignore_dotfiles = false
      @excluded_files = []
      @dry_run = false
      @prune = false
      @optimized = false

      loop do
        case @subargs[0]
        when "--no-gitignore"
          @subargs.shift
          @no_gitignore = true
        when "--ignore-dotfiles"
          @subargs.shift
          @ignore_dotfiles = true
        when "-e"
          @subargs.shift
          filepath = Pathname.new(@subargs.shift).cleanpath.to_s

          if File.file?(filepath)
            @excluded_files.push(filepath)
          elsif File.directory?(filepath)
            folder_files = Dir.glob(File.join(filepath, "**", "*"), File::FNM_DOTMATCH).push(filepath)
            @excluded_files += folder_files
          end
        when "--dry-run"
          @subargs.shift
          @dry_run = true
        when "--prune"
          @subargs.shift
          @prune = true
        when "--optimized"
          @subargs.shift
          @optimized = true
        when /^-/
          @display.display_unknown_option(@subargs[0])
          @display.display_push_help_and_exit
        else
          break
        end
      end

      if @subargs[0].nil?
        @display.display_response(result: "error", message: "no local path provided")
        @display.display_push_help_and_exit
      end

      root_path = Pathname @subargs[0]

      unless root_path.exist?
        @display.display_response(result: "error", message: "path #{root_path} does not exist")
        @display.display_push_help_and_exit
      end

      unless root_path.directory?
        @display.display_response(result: "error", message: "provided path is not a directory")
        @display.display_push_help_and_exit
      end

      @display.display_dry_run_notice if @dry_run

      if @prune
        pruned_dirs = []
        resp = @client.list
        resp[:files].each do |file|
          path = Pathname(File.join(@subargs[0], file[:path]))

          pruned_dirs << path if !path.exist? && file[:is_directory]

          next unless !path.exist? && !pruned_dirs.include?(path.dirname)

          @display.display_delete_progress(file[:path])
          resp = @client.delete_wrapper_with_dry_run file[:path], @dry_run

          if resp[:result] == "success"
            @display.display_delete_success
          else
            @display.display_delete_error(resp)
          end
        end
      end

      Dir.chdir(root_path) do
        paths = Dir.glob(File.join("**", "*"), File::FNM_DOTMATCH)

        if @no_gitignore == false && File.exist?(".gitignore")
          ignores = File.readlines(".gitignore").map do |ignore|
            ignore = ignore.strip
            File.directory?(ignore) ? "#{ignore}**" : ignore
          end

          paths.select! do |path|
            ignores.none? { |ignore| File.fnmatch?(ignore, path) }
          end

          @display.display_gitignore_hint
        end

        @excluded_files += paths.select { |path| path.start_with?(".") } if @ignore_dotfiles

        # do not upload files which already uploaded (checking by sha1_hash)
        if @optimized
          hex = paths.select { |path| File.file?(path) }
                     .map { |file| { filepath: file, sha1_hash: Digest::SHA1.file(file).hexdigest } }

          res = @client.list
          server_hex = res[:files].map { |n| n[:sha1_hash] }.compact

          uploaded_files = hex.select { |n| server_hex.include?(n[:sha1_hash]) }
                              .map { |n| n[:filepath] }
          @excluded_files += uploaded_files
        end

        paths -= @excluded_files
        paths.collect! { |path| Pathname path }

        task_queue = Queue.new
        paths.each { |path| task_queue.push(path) }

        threads = []

        MAX_THREADS.times do
          threads << Thread.new do
            until task_queue.empty?
              path = begin
                task_queue.pop(true)
              rescue StandardError
                nil
              end
              next if path.nil? || path.directory?

              Services::FileUploader.new(@client, path, path).upload
            end
          end
        end

        threads.each(&:join)
        @display.display_upload_complete
      end
    end

    def upload
      @display.display_upload_help_and_exit if @subargs[0].nil? || @subargs[1].nil?

      if File.file?(@subargs[0])
        Services::FileUploader.new(@client, @subargs[0], @subargs[1]).upload
      elsif File.directory?(@subargs[0])
        folder_uploader = Services::FolderUploader.new(@client, @subargs[0], @subargs[1])
        files_list = folder_uploader.files
        folder_uploader.upload(files_list)
      end
    end

    def pull
      quiet = ["--quiet", "-q"].include?(@subargs[0])

      file = File.read(@app_config_path)
      data = JSON.parse(file)

      last_pull_time = data.dig("LAST_PULL", "time")
      last_pull_loc = data.dig("LAST_PULL", "loc")

      Services::SiteExporter.new(@client, @sitename, data, @app_config_path)
                            .export(quiet:, last_pull_time:, last_pull_loc:)
    end

    # only for development purposes
    def purge
      resp = @client.list
      resp[:files].each do |file|
        @display.display_delete_progress(file[:path])
        resp = @client.delete_wrapper_with_dry_run file[:path], @dry_run

        if resp[:result] == "success"
          @display.display_delete_success
        else
          @display.display_delete_error(resp)
        end
      end
    end

    def pizza
      @display.display_pizza_help_and_exit
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
      when :linux, :freebsd
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
        # unknown UNIX-like systems
        return File.join(Dir.home, ".#{name}") if Dir.home
      end

      nil
    end
  end
end
