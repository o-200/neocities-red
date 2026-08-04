# frozen_string_literal: true

module NeocitiesRed
  module Services
    module File
      # Deletes a single file from the remote Neocities site.
      #
      # Displays progress and result feedback via {CliDisplay}.
      #
      # @example
      #   remover = NeocitiesRed::Services::File::Remover.new(client, "old-file.html", display: display)
      #   remover.remove
      #
      # @see NeocitiesRed::Client#delete Underlying delete API call
      class Remover
        # @return [NeocitiesRed::Client] the authenticated API client
        attr_accessor :client

        # @return [String] the remote file path to delete
        attr_accessor :filepath

        # @param client [NeocitiesRed::Client] authenticated API client
        # @param filepath [String] remote file path to delete
        # @param display [NeocitiesRed::CliDisplay] output helper
        def initialize(client, filepath, display: NeocitiesRed::CliDisplay.new)
          @client = client
          @filepath = filepath
          @display = display
        end

        # Deletes the file from the remote site.
        #
        # @return [Hash] API response with +:result+ key ("success" or "error")
        def remove
          @display.display_delete_progress(filepath)

          response = @client.delete(filepath)

          if response[:result] == "success"
            @display.display_delete_success
          else
            @display.display_delete_error(response)
          end

          response
        end
      end
    end
  end
end
