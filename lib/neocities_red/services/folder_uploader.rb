# frozen_string_literal: true

require "pathname"
require "pastel"

module NeocitiesRed
  module Services
    class FileIsNotExists < StandardError; end

    # warning - the big quantity of working threads could be considered like-a DDOS.
    # Your ip-address could get banned for a few days.
    MAX_THREADS = 5

    class FolderUploader
      def initialize(client, filepath, remote_path)
        @client = client
        @filepath = filepath
        @remote_path = remote_path
        @pastel = Pastel.new(eachline: "\n")
      end

      def get_files
        path = Pathname.new(File.expand_path(@filepath))

        raise FileIsNotExists, "#{path} does not exist locally." unless path.exist?

        if path.file?
          puts @pastel.bold("#{path} is not a directory, skipping")
          return
        end

        Dir.chdir(path) do
          Dir.glob("**/*", File::FNM_DOTMATCH)
             .select { |f| File.file?(f) }
        end
      end

      def upload(files_list, threads = MAX_THREADS)
        base = File.expand_path(@filepath)

        queue = Queue.new
        files_list.each { |file| queue << file }

        workers = Array.new(threads) do
          Thread.new do
            loop do
              begin
                file = queue.pop(true)
              rescue ThreadError
                break
              end

              local_path  = File.join(base, file)
              remote_path = File.join(@remote_path, file)

              FileUploader.new(@client, local_path, remote_path).upload
            end
          end
        end

        workers.each(&:join)
      end
    end
  end
end
