# frozen_string_literal: true

require "whirly"
require "pastel"

module NeocitiesRed
  module Services
    module Site
      class Exporter
        attr_accessor :client, :sitename, :data, :app_config_path

        def initialize(client, sitename, data, app_config_path)
          @client = client
          @sitename = sitename
          @data = data
          @app_config_path = app_config_path
          @pastel = Pastel.new(eachline: "\n")
        end

        def export(quiet: false, last_pull_time: nil, last_pull_loc: nil)
          if quiet
            Whirly.start spinner: ["😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"],
                         status: "Retrieving files for #{@pastel.bold @sitename}"
          end

          @client.pull(@sitename, last_pull_time, last_pull_loc, quiet: quiet)

          # write last pull data to file (not necessarily the best way to do this, but better than cloning every time)
          data["LAST_PULL"] = {
            time: Time.now,
            loc: Dir.pwd
          }

          File.write(app_config_path, data.to_json)
        rescue StandardError => e
          e
        ensure
          Whirly.stop if quiet
        end
      end
    end
  end
end
