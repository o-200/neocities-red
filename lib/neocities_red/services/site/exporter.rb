# frozen_string_literal: true

require "whirly"
require "pastel"
require "uri"
require "time"
require "fileutils"

module NeocitiesRed
  module Services
    module Site
      # Downloads all files from the remote Neocities site to the local filesystem.
      #
      # Supports incremental pulls — files that haven't been updated since the
      # last pull (and exist locally) are skipped. Progress is displayed per-file,
      # or via a Whirly spinner in quiet mode. Pull metadata (timestamp and
      # working directory) is persisted in the config file for future incremental
      # pulls.
      #
      # @example Full pull
      #   exporter = NeocitiesRed::Services::Site::Exporter.new(
      #     client, "my-site", config_data, config_path, display: display
      #   )
      #   exporter.export
      #
      # @example Quiet pull with incremental support
      #   exporter.export(quiet: true, last_pull_time: "2024-01-01", last_pull_loc: "/path/to/site")
      #
      # @see NeocitiesRed::Client#list Fetches remote file list
      # @see NeocitiesRed::Client#download Downloads individual files
      class Exporter
        # @return [NeocitiesRed::Client] the authenticated API client
        attr_accessor :client

        # @return [String] the site name being exported
        attr_accessor :sitename

        # @return [Hash] the current config data (modified in-place with last pull info)
        attr_accessor :data

        # @return [String] path to the config file for persisting pull metadata
        attr_accessor :app_config_path

        # @param client [NeocitiesRed::Client] authenticated API client
        # @param sitename [String] the Neocities site name
        # @param data [Hash] current application config data
        # @param app_config_path [String] path to the config file
        # @param display [NeocitiesRed::CliDisplay] output helper
        def initialize(client, sitename, data, app_config_path, display:)
          @client = client
          @sitename = sitename
          @data = data
          @app_config_path = app_config_path
          @display = display
          @pastel = Pastel.new(eachline: "\n")
        end

        # Downloads all site files to the current working directory.
        #
        # After the download, persists the current timestamp and working
        # directory to the config file for future incremental pulls.
        #
        # @param quiet [Boolean] when true, shows a spinner instead of per-file output
        # @param last_pull_time [String, nil] ISO timestamp of the last pull
        # @param last_pull_loc [String, nil] working directory of the last pull
        # @return [void]
        def export(quiet: false, last_pull_time: nil, last_pull_loc: nil)
          if quiet
            Whirly.start spinner: ["😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"],
                         status: "Retrieving files for #{@pastel.bold @sitename}"
          end

          fetch_files(last_pull_time, last_pull_loc, quiet)

          data["LAST_PULL"] = {
            time: Time.now,
            loc: Dir.pwd
          }

          ::File.write(app_config_path, data.to_json)
        ensure
          Whirly.stop if quiet
        end

        private

        # Fetches each file from the remote site and writes it locally.
        #
        # Skips files that haven't changed since the last pull when
        # incremental data is available.
        #
        # @param last_pull_time [String, nil] ISO timestamp of the last pull
        # @param last_pull_loc [String, nil] working directory of the last pull
        # @param quiet [Boolean] suppresses per-file output when true
        # @return [void]
        # @raise [NeocitiesRed::APIError] if the site info or file list API fails
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

          success_loaded = 0
          start_time = Time.now
          curr_dir = Dir.pwd

          resp = @client.list

          raise NeocitiesRed::APIError, resp[:message] if resp[:result] == "error"

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
                 ::File.exist?(file[:path])

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

          @display.display_pull_stats(success_loaded, Time.now - start_time)
        end
      end
    end
  end
end
