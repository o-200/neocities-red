# frozen_string_literal: true

require "pathname"

module NeocitiesRed
  module Services
    module File
      # Maximum number of concurrent upload threads.
      #
      # Warning: a high thread count may be flagged as DDOS-like traffic
      # by Neocities, potentially resulting in a temporary IP ban.
      MAX_THREADS = 5

      # Uploads all files in a local directory to the remote site in parallel.
      #
      # Uses a {Services::Common::WorkerPool} to upload files concurrently
      # up to {MAX_THREADS} threads. Each file is uploaded via {Uploader}.
      #
      # @example
      #   folder = NeocitiesRed::Services::File::FolderUploader.new(client, "./dist", "assets", display: display)
      #   files = folder.files
      #   folder.upload(files)
      #
      # @see NeocitiesRed::Services::File::Uploader Individual file upload
      # @see NeocitiesRed::Services::Common::WorkerPool Thread pool
      class FolderUploader
        # @param client [NeocitiesRed::Client] authenticated API client
        # @param filepath [String] local directory path to upload
        # @param remote_path [String] remote destination directory
        # @param display [NeocitiesRed::CliDisplay] output helper
        def initialize(client, filepath, remote_path, display: NeocitiesRed::CliDisplay.new)
          @client = client
          @filepath = filepath
          @remote_path = remote_path
          @display = display
        end

        # Recursively lists all files in the local directory.
        #
        # @return [Array<String>] relative file paths within the directory
        # @raise [NeocitiesRed::FileNotFoundError] if the directory does not exist
        # @return [nil] if the path is a file (not a directory)
        def files
          path = Pathname.new(::File.expand_path(@filepath))

          raise NeocitiesRed::FileNotFoundError, "#{path} does not exist locally." unless path.exist?

          if path.file?
            @display.display_skip_file(path)
            return
          end

          Dir.chdir(path) do
            Dir.glob("**/*", ::File::FNM_DOTMATCH)
               .select { |f| ::File.file?(f) }
          end
        end

        # Uploads all files in the list concurrently.
        #
        # @param files_list [Array<String>] relative file paths to upload
        # @param threads [Integer] maximum concurrent upload threads (default: {MAX_THREADS})
        # @return [void]
        def upload(files_list, threads = MAX_THREADS)
          base = ::File.expand_path(@filepath)

          worker_pool = Services::Common::WorkerPool.new(threads) do |file|
            local_path  = ::File.join(base, file)
            remote_path = ::File.join(@remote_path, file)

            Uploader.new(@client, local_path, remote_path, display: @display).upload
          end

          worker_pool.process(files_list)
        end
      end
    end
  end
end
