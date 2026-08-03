# frozen_string_literal: true

require "pastel"
require "time"
require "tty/table"

module NeocitiesRed
  module Services
    module File
      class List
        def initialize(client, path, detail, display: NeocitiesRed::CliDisplay.new)
          @client = client
          @path = path
          @detail = detail || false
          @display = display
          @pastel = Pastel.new(eachline: "\n")
        end

        def list
          files_from_response
        end

        def show
          files = files_from_response

          return files unless @detail

          out = [
            [@pastel.bold("Path"), @pastel.bold("Size"), @pastel.bold("sha1_Hash"),
             @pastel.bold("Updated")]
          ]

          files.each do |file|
            out.push([
                       @pastel.send(file[:is_directory] ? :blue : :green).bold(file[:path]),
                       file[:size] || "",
                       file[:sha1_hash],
                       Time.parse(file[:updated_at]).localtime
                     ])
          end

          @display.display_list_table(TTY::Table.new(out))

          files
        end

        private

        def files_from_response
          resp = @client.list(@path)

          raise NeocitiesRed::APIError, resp[:message] || resp[:error_type] || resp.inspect if resp[:result] == "error"

          resp[:files]
        end
      end
    end
  end
end
