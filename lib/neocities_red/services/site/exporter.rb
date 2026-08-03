# frozen_string_literal: true

require "whirly"
require "pastel"
require "uri"
require "time"
require "fileutils"

module NeocitiesRed
  module Services
    module Site
      class Exporter
        attr_accessor :client, :sitename, :data, :app_config_path

        def initialize(client, sitename, data, app_config_path, display:)
          @client = client
          @sitename = sitename
          @data = data
          @app_config_path = app_config_path
          @display = display
          @pastel = Pastel.new(eachline: "\n")
        end

        def export(quiet: false, last_pull_time: nil, last_pull_loc: nil)
          if quiet
            Whirly.start spinner: ["😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"],
                         status: "Retrieving files for #{@pastel.bold @sitename}"
          end

          fetch_files(last_pull_time, last_pull_loc, quiet)

          # write last pull data to file (not necessarily the best way to do this, but better than cloning every time)
          data["LAST_PULL"] = {
            time: Time.now,
            loc: Dir.pwd
          }

          ::File.write(app_config_path, data.to_json)
        ensure
          Whirly.stop if quiet
        end

        private

        def fetch_files(last_pull_time, last_pull_loc, quiet)
          site_info = @client.info(@sitename)

          raise NeocitiesRed::APIError, site_info[:message] if site_info[:result] == "error"

          info_data = site_info[:info]

          domain =
            if info_data[:domain].to_s.empty?
              "https://#{@sitename}.neocities.org/"
            else
              "https://#{info_data[:domain]}/"
            end

          # start stats
          success_loaded = 0
          start_time = Time.now
          curr_dir = Dir.pwd

          # get list of files
          resp = @client.list

          raise NeocitiesRed::APIError, resp[:message] if resp[:result] == "error"

          # fetch each file
          uri_parser = URI::Parser.new
          resp[:files].each do |file|
            if file[:is_directory]
              FileUtils.mkdir_p file[:path].to_s
            else
              @display.display_pull_progress(file[:path]) unless quiet

              if last_pull_time &&
                 last_pull_loc &&
                 Time.parse(file[:updated_at]) <= Time.parse(last_pull_time) &&
                 last_pull_loc == curr_dir &&
                 ::File.exist?(file[:path]) # case when user deletes file

                # case when file hasn't been updated since last
                @display.display_pull_no_updates unless quiet

                next
              end

              pathtotry = uri_parser.escape(domain + file[:path])
              fileconts = @client.download(pathtotry)

              if fileconts.status == 200
                @display.display_pull_success unless quiet
                success_loaded += 1

                ::File.write(file[:path].to_s, fileconts.body)
              elsif !quiet
                @display.display_pull_failure
              end
            end
          end

          # display stats
          @display.display_pull_stats(success_loaded, Time.now - start_time)
        end
      end
    end
  end
end
