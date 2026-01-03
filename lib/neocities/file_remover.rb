require 'pastel'

module Neocities
  class FileRemover
    attr_accessor :client, :filepath

    def initialize(client, filepath)
      @client = client
      @filepath = filepath
      @pastel = Pastel.new(eachline: "\n")
    end

    def remove
      puts @pastel.bold("Deleting #{filepath} ...")
      
      response = @client.delete(filepath)

      if response[:result] == 'error'
        puts @pastel.bold(response[:message])
      end

      if response[:result] == 'error' && response[:error_type] == 'file_exists'
        print @pastel.yellow.bold("EXISTS")
      elsif response[:result] == 'success'
        print @pastel.green.bold("SUCCESS")
      end

      response
    end
  end
end