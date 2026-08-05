# frozen_string_literal: true

require "spec_helper"
require "json"
require "fileutils"
require "time"

RSpec.describe NeocitiesRed::Services::Site::Exporter do
  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:sitename) { "test-site" }
  let(:spec_root) { File.expand_path("..", __dir__) }
  let(:tmp_root) { File.join(spec_root, "tmp", "site_exporter_spec") }
  let(:config_path) { File.join(tmp_root, "config.json") }
  let(:data) { { "LAST_PULL" => { "time" => nil, "loc" => nil } } }
  let(:display) do
    instance_double(
      NeocitiesRed::CliDisplay,
      display_pull_progress: nil,
      display_pull_no_updates: nil,
      display_pull_success: nil,
      display_pull_failure: nil,
      display_pull_stats: nil
    )
  end
  let(:exporter) { described_class.new(client, sitename, data, config_path, display: display) }
  let(:info_response) { { result: "success", info: { domain: nil } } }
  let(:list_response) { { result: "success", files: [] } }

  around do |example|
    FileUtils.rm_rf(tmp_root)
    FileUtils.mkdir_p(tmp_root)
    File.write(config_path, data.to_json)

    original_dir = Dir.pwd
    Dir.chdir(tmp_root)
    example.run
  ensure
    Dir.chdir(original_dir)
    FileUtils.rm_rf(tmp_root)
  end

  before do
    allow(client).to receive_messages(info: info_response, list: list_response)
  end

  describe "#export" do
    context "when the site has no files" do
      it "updates the config file with last pull data" do
        expect { exporter.export(quiet: true, last_pull_time: nil, last_pull_loc: nil) }.not_to raise_error

        updated_data = JSON.parse(File.read(config_path))
        expect(updated_data["LAST_PULL"]).to have_key("time")
        expect(updated_data["LAST_PULL"]).to have_key("loc")
      end

      it "uses Whirly spinner when quiet mode is enabled" do
        allow(Whirly).to receive(:start)
        allow(Whirly).to receive(:stop)

        expect { exporter.export(quiet: true, last_pull_time: nil, last_pull_loc: nil) }.not_to raise_error

        expect(Whirly).to have_received(:start).with(
          spinner: ["😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"],
          status: anything
        )
        expect(Whirly).to have_received(:stop)
      end

      it "does not use Whirly spinner when quiet mode is disabled" do
        allow(Whirly).to receive(:start)
        allow(Whirly).to receive(:stop)

        expect { exporter.export(quiet: false, last_pull_time: nil, last_pull_loc: nil) }.not_to raise_error

        expect(Whirly).not_to have_received(:start)
        expect(Whirly).not_to have_received(:stop)
      end

      it "displays pull stats" do
        exporter.export(quiet: false, last_pull_time: nil, last_pull_loc: nil)

        expect(display).to have_received(:display_pull_stats).with(0, anything)
      end
    end

    context "when the site has files" do
      let(:list_response) do
        {
          result: "success",
          files: [
            { path: "index.html", is_directory: false, updated_at: "2024-01-01T00:00:00Z" },
            { path: "assets/", is_directory: true, updated_at: "2024-01-01T00:00:00Z" }
          ]
        }
      end
      let(:file_response) { instance_double(Faraday::Response, status: 200, body: "<h1>Hello</h1>") }

      it "downloads files and writes them locally" do
        allow(client).to receive(:download).with("https://test-site.neocities.org/index.html").and_return(file_response)

        exporter.export(quiet: false, last_pull_time: nil, last_pull_loc: nil)

        expect(File.read(File.join(tmp_root, "index.html"))).to eq("<h1>Hello</h1>")
        expect(File.directory?(File.join(tmp_root, "assets"))).to be(true)
        expect(display).to have_received(:display_pull_success)
      end

      it "uses the custom domain when present" do
        allow(client).to receive(:info).and_return(result: "success", info: { domain: "example.com" })
        allow(client).to receive(:download).with("https://example.com/index.html").and_return(file_response)

        exporter.export(quiet: false, last_pull_time: nil, last_pull_loc: nil)

        expect(client).to have_received(:download).with("https://example.com/index.html")
      end

      it "skips download when the file has not changed since last pull" do
        allow(client).to receive(:download)
        File.write(File.join(tmp_root, "index.html"), "existing content")

        last_pull_time = Time.now.iso8601
        exporter.export(quiet: false, last_pull_time: last_pull_time, last_pull_loc: Dir.pwd)

        expect(display).to have_received(:display_pull_no_updates)
        expect(client).not_to have_received(:download)
        expect(File.read(File.join(tmp_root, "index.html"))).to eq("existing content")
      end

      it "reports failure when the download fails" do
        allow(client).to receive(:download).with("https://test-site.neocities.org/index.html").and_return(
          instance_double(Faraday::Response, status: 500, body: "")
        )

        exporter.export(quiet: false, last_pull_time: nil, last_pull_loc: nil)

        expect(display).to have_received(:display_pull_failure)
        expect(File.exist?(File.join(tmp_root, "index.html"))).to be(false)
      end
    end

    context "when the API returns an error for info" do
      let(:info_response) { { result: "error", message: "Site not found" } }

      it "raises APIError" do
        expect do
          exporter.export(quiet: true, last_pull_time: nil, last_pull_loc: nil)
        end.to raise_error(NeocitiesRed::APIError, /Site not found/)
      end
    end

    context "when the API returns an error for list" do
      let(:list_response) { { result: "error", message: "List failed" } }

      it "raises APIError" do
        expect do
          exporter.export(quiet: true, last_pull_time: nil, last_pull_loc: nil)
        end.to raise_error(NeocitiesRed::APIError, /List failed/)
      end
    end

    context "when fetching raises an error" do
      it "propagates the error and stops Whirly" do
        allow(client).to receive(:info).and_raise(StandardError.new("network error"))
        allow(Whirly).to receive(:start)
        allow(Whirly).to receive(:stop)

        expect do
          exporter.export(quiet: true, last_pull_time: nil, last_pull_loc: nil)
        end.to raise_error(StandardError, "network error")
        expect(Whirly).to have_received(:stop)
      end
    end
  end

  describe "#initialize" do
    it "stores client, sitename, data, and app_config_path" do
      expect(exporter.client).to eq(client)
      expect(exporter.sitename).to eq(sitename)
      expect(exporter.data).to eq(data)
      expect(exporter.app_config_path).to eq(config_path)
    end
  end
end
