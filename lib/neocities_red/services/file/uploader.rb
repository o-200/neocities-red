# frozen_string_literal: true

require "pathname"

module NeocitiesRed
  module Services
    module File
      class Uploader
        def initialize(client, filepath, remote_path = nil, display: NeocitiesRed::CliDisplay.new)
          @client = client
          @filepath = filepath
          @remote_path = remote_path
          @display = display
        end

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
