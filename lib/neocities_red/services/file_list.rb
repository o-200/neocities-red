# frozen_string_literal: true

require "pastel"
require "time"
require "tty/table"

module NeocitiesRed
  module Services
    class FileList
      def initialize(client, path, detail)
        @client = client
        @path = path
        @detail = detail || false
        @pastel = Pastel.new(eachline: "\n")
      end

      def list
        resp = @client.list(@path)

        display_error_and_exit(resp) if resp[:result] == "error"

        resp[:files]
      end

      def show
        resp = @client.list(@path)

        display_error_and_exit(resp) if resp[:result] == "error"

        if @detail
          out = [
            [@pastel.bold("Path"), @pastel.bold("Size"), @pastel.bold("sha1_Hash"),
             @pastel.bold("Updated")]
          ]

          resp[:files].each do |file|
            out.push([
                       @pastel.send(file[:is_directory] ? :blue : :green).bold(file[:path]),
                       file[:size] || "",
                       file[:sha1_hash],
                       Time.parse(file[:updated_at]).localtime
                     ])
          end

          puts TTY::Table.new(out)
        end

        resp[:files].map do |file|
          @pastel.send(file[:is_directory] ? :blue : :green).bold(file[:path])
        end

        resp[:files]
      end

      private

      def display_error_and_exit(resp)
        puts(resp[:message] || resp[:error_type] || resp.inspect)
        exit
      end
    end
  end
end
