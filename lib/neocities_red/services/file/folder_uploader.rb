# frozen_string_literal: true

require "pathname"

module NeocitiesRed
  module Services
    module File
      # warning - the big quantity of working threads could be considered like-a DDOS.
      # Your ip-address could get banned for a few days.
      MAX_THREADS = 5

      class FolderUploader
        def initialize(client, filepath, remote_path, display: NeocitiesRed::CliDisplay.new)
          @client = client
          @filepath = filepath
          @remote_path = remote_path
          @display = display
        end

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
