# frozen_string_literal: true

require "spec_helper"
require "json"
require "fileutils"

RSpec.describe NeocitiesRed::Services::SiteExporter do
  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:sitename) { "test-site" }
  let(:spec_root) { File.expand_path("..", __dir__) }
  let(:tmp_root) { File.join(spec_root, "tmp", "site_exporter_spec") }
  let(:config_path) { File.join(tmp_root, "config.json") }
  let(:data) { { "LAST_PULL" => { "time" => nil, "loc" => nil } } }

  before do
    FileUtils.rm_rf(tmp_root)
    FileUtils.mkdir_p(tmp_root)
    File.write(config_path, data.to_json)
  end

  after do
    FileUtils.rm_rf(tmp_root)
  end

  describe "#export" do
    context "when pull is successful" do
      let(:exporter) { described_class.new(client, sitename, data, config_path) }

      before do
        allow(client).to receive(:pull).and_return(nil)
      end

      it "pulls files from the site and updates the config file" do
        expect { exporter.export(true, nil, nil) }.not_to raise_error

        expect(File.exist?(config_path)).to be(true)
        updated_data = JSON.parse(File.read(config_path))
        expect(updated_data["LAST_PULL"]).to have_key("time")
        expect(updated_data["LAST_PULL"]).to have_key("loc")
      end

      it "uses Whirly spinner when quiet mode is enabled" do
        allow(Whirly).to receive(:start)
        allow(Whirly).to receive(:stop)

        expect { exporter.export(true, nil, nil) }.not_to raise_error

        expect(Whirly).to have_received(:start).with(
          spinner: ["😺", "😸", "😹", "😻", "😼", "😽", "🙀", "😿", "😾"],
          status: anything
        )
        expect(Whirly).to have_received(:stop)
      end

      it "does not use Whirly spinner when quiet mode is disabled" do
        allow(Whirly).to receive(:start)
        allow(Whirly).to receive(:stop)

        expect { exporter.export(false, nil, nil) }.not_to raise_error

        expect(Whirly).not_to have_received(:start)
        expect(Whirly).not_to have_received(:stop)
      end

      context "with last_pull_time and last_pull_loc" do
        let(:last_pull_time) { "2024-01-01T00:00:00Z" }
        let(:last_pull_loc) { tmp_root }

        it "passes last_pull parameters to client.pull" do
          expect { exporter.export(true, last_pull_time, last_pull_loc) }.not_to raise_error

          expect(client).to have_received(:pull).with(
            sitename, last_pull_time, last_pull_loc, quiet: true
          )
        end
      end
    end

    context "when pull raises an error" do
      let(:exporter) { described_class.new(client, sitename, data, config_path) }

      it "stops Whirly and returns the error" do
        allow(Whirly).to receive(:start)
        allow(Whirly).to receive(:stop)
        allow(client).to receive(:pull).and_raise(StandardError.new("network error"))

        result = exporter.export(true, nil, nil)

        expect(result).to be_a(StandardError)
        expect(result.message).to eq("network error")
        expect(Whirly).to have_received(:stop)
      end

      it "does not raise and returns an error object" do
        allow(Whirly).to receive(:start)
        allow(Whirly).to receive(:stop)
        allow(client).to receive(:pull).and_raise(StandardError.new("network error"))

        result = nil
        expect { result = exporter.export(true, nil, nil) }.not_to raise_error
        expect(result).to be_a(StandardError)
      end
    end
  end

  describe "#initialize" do
    it "stores client, sitename, data, and app_config_path" do
      exporter = described_class.new(client, sitename, data, config_path)

      expect(exporter.client).to eq(client)
      expect(exporter.sitename).to eq(sitename)
      expect(exporter.data).to eq(data)
      expect(exporter.app_config_path).to eq(config_path)
    end
  end
end
