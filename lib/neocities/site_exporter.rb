# frozen_string_literal: true

require 'whirly'
require 'pastel'

module Neocities
  class SiteExporter
    attr_accessor :client, :sitename, :data, :app_config_path

    def initialize(client, sitename, data, app_config_path)
      @client = client
      @sitename = sitename
      @data = data
      @app_config_path = app_config_path
    end

    def export(quiet, last_pull_time, last_pull_loc)
      if quiet
        Whirly.start spinner: ['😺', '😸', '😹', '😻', '😼', '😽', '🙀', '😿', '😾'],
                     status: "Retrieving files for #{@pastel.bold @sitename}"
      end

      @client.pull(@sitename, last_pull_time, last_pull_loc, quiet)

      # write last pull data to file (not necessarily the best way to do this, but better than cloning every time)
      data['LAST_PULL'] = {
        "time": Time.now,
        "loc": Dir.pwd
      }

      File.write(app_config_path, data.to_json)
    rescue StandardError => e
      Whirly.stop if quiet

      e
    ensure
      exit
    end
  end
end
