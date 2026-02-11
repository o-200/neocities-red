# frozen_string_literal: true

require 'pathname'
require 'pastel'

module Neocities
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

      def upload
        path = Pathname(@filepath)

        raise FileIsNotExists, "#{path} does not exist locally." unless path.exist?

        if path.file?
          puts @pastel.bold("#{path} is not a directory, skipping")
          return
        end

        Dir.chdir(path) do
          files = Dir.glob('**/*', File::FNM_DOTMATCH).select { |f| File.file?(f) }

          queue = Queue.new
          files.each { |file| queue << file }

          workers = Array.new(MAX_THREADS) do
            Thread.new do
              loop do
                begin
                  file = queue.pop(true)
                rescue ThreadError
                  break # queue is empty
                end

                remote_path = File.join(@remote_path, file)
                FileUploader.new(@client, file, remote_path).upload
              end
            end
          end

          workers.each(&:join)
        end
      end
    end
  end
end
