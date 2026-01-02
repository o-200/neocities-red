# lib/neocities/profile_info.rb
require 'time'
require 'pastel'

module Neocities
  class ClientError < StandardError; end

  class ProfileInfo
    attr_accessor :client

    def initialize(client, subargs = [], sitename = nil)
      @client = client
      @subargs = subargs
      @sitename = sitename
      @pastel = Pastel.new(eachline: "\n")
    end

    def get_stats
      response = @client.info(@subargs[0] || @sitename)
      
      if response[:result] == 'error'
        raise ClientError, response
      end

      response
    end

    def pretty_print
      out = []

      get_stats[:info].each do |k, v|
        if v && [:created_at, :last_updated].include?(k) 
          v = Time.parse(v).localtime
        end

        out << [@pastel.bold(k.to_s), v]
      end

      out
    end
  end
end