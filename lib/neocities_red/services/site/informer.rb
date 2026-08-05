# frozen_string_literal: true

require "time"
require "pastel"

module NeocitiesRed
  module Services
    module Site
      # Retrieves and formats site information for the Neocities site.
      #
      # Queries the Neocities API for site metadata (domain, bandwidth,
      # created_at, last_updated, etc.) and formats it as rows suitable
      # for display in a TTY::Table.
      #
      # @example
      #   informer = NeocitiesRed::Services::Site::Informer.new(client, ["my-site"], "my-site")
      #   rows = informer.pretty_print
      #   puts TTY::Table.new(rows)
      #
      # @see NeocitiesRed::Client#info Underlying API call
      class Informer
        # @return [NeocitiesRed::Client] the authenticated API client
        attr_reader :client

        # @param client [NeocitiesRed::Client] authenticated API client
        # @param subargs [Array<String>] CLI subarguments; the first element
        #   may be a sitename to query
        # @param sitename [String, nil] default sitename (used when subargs is empty)
        def initialize(client, subargs = [], sitename = nil)
          @client = client
          @subargs = subargs
          @sitename = sitename
          @pastel = Pastel.new(eachline: "\n")
        end

        # Fetches site information from the Neocities API.
        #
        # @return [Hash] parsed API response containing +:info+ with site metadata
        # @raise [NeocitiesRed::APIError] if the API returns an error
        def stats
          response = @client.info(@subargs[0] || @sitename)

          raise NeocitiesRed::APIError, response[:message] if response[:result] == "error"

          response
        end

        # Formats the site stats as bold-labeled rows.
        #
        # Timestamp fields (+created_at+, +last_updated+) are converted
        # to local time for readability.
        #
        # @return [Array<Array(String, Object)>] array of +[label, value]+ pairs
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
end
