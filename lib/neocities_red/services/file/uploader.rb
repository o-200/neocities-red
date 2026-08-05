# frozen_string_literal: true

require "pathname"

module NeocitiesRed
  module Services
    module File
      # Uploads a single file to the Neocities site.
      #
      # Handles display feedback for the upload lifecycle: progress,
      # success, already-exists, and directory-skip scenarios.
      #
      # @example
      #   uploader = NeocitiesRed::Services::File::Uploader.new(client, "index.html", display: display)
      #   uploader.upload
      #
      # @see NeocitiesRed::Client#upload Underlying upload method
      class Uploader
        # @param client [NeocitiesRed::Client] authenticated API client
        # @param filepath [String] local file path to upload
        # @param remote_path [String, nil] remote destination path;
        #   defaults to the file's basename
        # @param display [NeocitiesRed::CliDisplay] output helper
        def initialize(client, filepath, remote_path = nil, display: NeocitiesRed::CliDisplay.new)
          @client = client
          @filepath = filepath
          @remote_path = remote_path
          @display = display
        end

        # Uploads the file to the remote site.
        #
        # Skips directories with a display message. Computes the SHA1 hash
        # and skips the upload if the remote file is identical.
        #
        # @return [Hash] API response with +:result+ key
        # @raise [NeocitiesRed::FileNotFoundError] if the local file does not exist
        def upload
          path = Pathname.new(@filepath)

          raise NeocitiesRed::FileNotFoundError, "#{path} does not exist locally." unless path.exist?

          if path.directory?
            @display.display_skip_directory(path)
            return
          end

          @display.display_upload_progress(path, @remote_path)

          response = @client.upload(path, @remote_path)

          if response[:result] == "success"
            @display.display_upload_success
          elsif response[:result] == "error" && response[:error_type] == "file_exists"
            @display.display_upload_exists
          else
            @display.display_response(response)
          end

          response
        end
      end
    end
  end
end
