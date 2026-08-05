# frozen_string_literal: true

require "pastel"
require "time"
require "tty/table"

module NeocitiesRed
  module Services
    # File-level operations: upload, delete, and list.
    module File
      # Lists files on the remote Neocities site.
      #
      # Supports both a simple list mode and a detailed table mode
      # with file size, SHA1 hash, and last-updated timestamp.
      #
      # @example Simple listing
      #   list = NeocitiesRed::Services::File::List.new(client, nil, false, display: display)
      #   files = list.show
      #
      # @example Detailed table
      #   list = NeocitiesRed::Services::File::List.new(client, nil, true, display: display)
      #   list.show  # renders TTY::Table
      #
      # @see NeocitiesRed::Client#list Underlying API call
      class List
        # @param client [NeocitiesRed::Client] authenticated API client
        # @param path [String, nil] remote directory path to list (nil for root)
        # @param detail [Boolean] when true, renders a detailed table with
        #   size, hash, and timestamp columns
        # @param display [NeocitiesRed::CliDisplay] output helper
        def initialize(client, path, detail, display: NeocitiesRed::CliDisplay.new)
          @client = client
          @path = path
          @detail = detail || false
          @display = display
          @pastel = Pastel.new(eachline: "\n")
        end

        # Returns the raw list of remote files.
        #
        # @return [Array<Hash>] array of file hashes with +:path+, +:is_directory+,
        #   +:size+, +:sha1_hash+, and +:updated_at+ keys
        # @raise [NeocitiesRed::APIError] if the API returns an error
        def list
          files_from_response
        end

        # Returns the file list, optionally rendered as a detailed table.
        #
        # In detail mode, displays a colored table with Path, Size, SHA1 Hash,
        # and Updated columns. Directories are shown in blue, files in green.
        #
        # @return [Array<Hash>] the file list hashes
        # @raise [NeocitiesRed::APIError] if the API returns an error
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

        # Fetches and validates the file list from the API.
        #
        # @return [Array<Hash>] file hashes from the API response
        # @raise [NeocitiesRed::APIError] if the response indicates an error
        def files_from_response
          resp = @client.list(@path)

          raise NeocitiesRed::APIError, resp[:message] || resp[:error_type] || resp.inspect if resp[:result] == "error"

          resp[:files]
        end
      end
    end
  end
end
