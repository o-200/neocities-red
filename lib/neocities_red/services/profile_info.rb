# frozen_string_literal: true

require "time"
require "pastel"

module NeocitiesRed
  module Services
    class ClientError < StandardError; end

    class ProfileInfo
      attr_accessor :client

      def initialize(client, subargs = [], sitename = nil)
        @client = client
        @subargs = subargs
        @sitename = sitename
        @pastel = Pastel.new(eachline: "\n")
      end

      def stats
        response = @client.info(@subargs[0] || @sitename)

        raise NeocitiesRed::Services::ClientError, response if response[:result] == "error"

        response
      end

      def pretty_print
        out = []

        stats[:info].each do |k, v|
          v = Time.parse(v).localtime if v && %i[created_at last_updated].include?(k)

          out << [@pastel.bold(k.to_s), v]
        end

        out
      end
    end
  end
end
