# frozen_string_literal: true

require 'pastel'
require 'tty/table'

module Neocities
  class FileList
    def initialize(client, path, detail)
      @client = client
      @path = path
      @detail = detail || false
      @pastel = Pastel.new(eachline: "\n")
    end

    def show
      resp = @client.list(@path)

      if resp[:result] == 'error'
        display_response resp
        exit
      end

      if @detail
        out = [
          [@pastel.bold('Path'), @pastel.bold('Size'), @pastel.bold('sha1_Hash'), @pastel.bold('Updated')]
        ]

        resp[:files].each do |file|
          out.push([
                     @pastel.send(file[:is_directory] ? :blue : :green).bold(file[:path]),
                     file[:size] || '',
                     file[:sha1_hash],
                     Time.parse(file[:updated_at]).localtime
                   ])
        end

        puts TTY::Table.new(out)
      end

      resp[:files].each do |file|
        puts @pastel.send(file[:is_directory] ? :blue : :green).bold(file[:path])
      end
    end
  end
end
