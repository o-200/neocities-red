# frozen_string_literal: true

module NeocitiesRed
  module Services
    module File
      class Remover
        attr_accessor :client, :filepath

        def initialize(client, filepath, display: NeocitiesRed::CliDisplay.new)
          @client = client
          @filepath = filepath
          @display = display
        end

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
