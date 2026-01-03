# frozen_string_literal: true

require 'pathname'
require 'pastel'

module Neocities
  class FileIsNotExists < StandardError; end

  class FileUploader
    def initialize(client, filepath, remote_path = nil)
      @client = client
      @filepath = filepath
      @remote_path = remote_path
      @pastel = Pastel.new(eachline: "\n")
    end

    def upload
      path = Pathname(@filepath)

      raise FileIsNotExists, "#{path} does not exist locally." unless path.exist?

      if path.directory?
        puts @pastel.bold("#{path} is a directory, skipping")
        return
      end

      remote_path = @remote_path || path

      puts @pastel.bold("Uploading #{path} to #{remote_path} ...")

      response = @client.upload(path, remote_path)
      puts response if response[:result] == 'error'

      if response[:result] == 'error' && response[:error_type] == 'file_exists'
        puts @pastel.yellow.bold('EXISTS')
      elsif response[:result] == 'success'
        puts @pastel.green.bold('SUCCESS')
      end

      response
    end
  end
end
