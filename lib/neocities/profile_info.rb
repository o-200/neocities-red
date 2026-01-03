# frozen_string_literal: true

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

      raise ClientError, response if response[:result] == 'error'

      response
    end

    def pretty_print
      out = []

      get_stats[:info].each do |k, v|
        v = Time.parse(v).localtime if v && %i[created_at last_updated].include?(k)

        out << [@pastel.bold(k.to_s), v]
      end

      out
    end
  end
end
