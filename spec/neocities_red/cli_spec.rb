# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "json"
require "stringio"

RSpec.describe NeocitiesRed::CLI do
  describe ".app_config_path" do
    let(:app_name) { "neocities" }

    around do |example|
      original_env = ENV.to_hash
      %w[XDG_CONFIG_HOME LOCALAPPDATA USERPROFILE].each { |key| ENV.delete(key) }
      example.run
    ensure
      ENV.replace(original_env)
    end

    it "uses XDG_CONFIG_HOME on linux when available" do
      stub_const("RUBY_PLATFORM", "x86_64-linux")
      allow(Dir).to receive(:home).and_return("/home/alice")
      ENV["XDG_CONFIG_HOME"] = "/tmp/xdg"

      path = described_class.app_config_path(app_name)
      expect(path).to eq(File.join("/tmp/xdg", app_name))
    end

    it "falls back to ~/.config on linux when XDG_CONFIG_HOME is missing" do
      stub_const("RUBY_PLATFORM", "x86_64-linux")
      allow(Dir).to receive(:home).and_return("/home/alice")

      path = described_class.app_config_path(app_name)
      expect(path).to eq(File.join("/home/alice", ".config", app_name))
    end

    it "uses macOS application support on darwin" do
      stub_const("RUBY_PLATFORM", "arm64-darwin23")
      allow(Dir).to receive(:home).and_return("/Users/alice")

      path = described_class.app_config_path(app_name)
      expect(path).to eq(File.join("/Users/alice", "Library", "Application Support", app_name))
    end

    it "uses LOCALAPPDATA on win32 when available" do
      stub_const("RUBY_PLATFORM", "x64-mingw32")
      ENV["LOCALAPPDATA"] = "C:/Users/alice/AppData/Local"

      path = described_class.app_config_path(app_name)
      expect(path).to eq(File.join("C:/Users/alice/AppData/Local", app_name))
    end

    it "falls back to USERPROFILE-based path on win32" do
      stub_const("RUBY_PLATFORM", "x64-mingw32")
      ENV["USERPROFILE"] = "C:/Users/alice"

      path = described_class.app_config_path(app_name)
      expect(path).to eq(
        File.join("C:/Users/alice", "AppData", "Local", app_name)
      )
    end

    it "uses ~/.neocities on freebsd" do
      stub_const("RUBY_PLATFORM", "amd64-freebsd14")
      allow(Dir).to receive(:home).and_return("/home/alice")

      path = described_class.app_config_path(app_name)
      expect(path).to eq(File.join("/home/alice", ".#{app_name}"))
    end
  end

  describe "#persist_config" do
    let(:tmp_dir) { Dir.mktmpdir }
    let(:config_path) { File.join(tmp_dir, "config.json") }
    let(:cli) { described_class.new }

    before do
      allow(cli).to receive(:app_config_path).and_return(config_path)
    end

    after do
      FileUtils.rm_rf(tmp_dir)
    end

    it "writes the config with 0600 permissions" do
      cli.send(:persist_config, API_KEY: "secret", SITENAME: "test-site")

      expect(File.read(config_path)).to eq('{"API_KEY":"secret","SITENAME":"test-site"}')
      skip "chmod is a no-op on Windows" if Gem.win_platform?
      expect(File.stat(config_path).mode & 0o777).to eq(0o600)
    end
  end

  describe "purge" do
    around do |example|
      # rubocop:disable RSpec/ExpectOutput
      original_stdout = $stdout
      $stdout = StringIO.new
      example.run
    ensure
      $stdout = original_stdout
    end
    # rubocop:enable RSpec/ExpectOutput

    let(:tmp_dir) { Dir.mktmpdir }
    let(:config_path) { File.join(tmp_dir, "config.json") }

    before do
      allow(described_class).to receive(:app_config_path).and_return(tmp_dir)
      File.write(config_path, JSON.generate(API_KEY: "test-key", SITENAME: "test-site"))

      stub_request(:get, %r{https://neocities\.org/api/list})
        .to_return(body: {
          result: "success",
          files: [
            { path: "index.html", is_directory: false },
            { path: "gone_dir", is_directory: true }
          ]
        }.to_json)
    end

    after do
      WebMock.reset!
      FileUtils.rm_rf(tmp_dir)
    end

    it "deletes listed files when confirmed" do
      stub_request(:post, %r{https://neocities\.org/api/delete})
        .to_return(body: { result: "success" }.to_json)

      described_class.start(%w[purge -y])

      expect(a_request(:post, %r{https://neocities\.org/api/delete}))
        .to have_been_made.twice
    end

    it "does not delete anything with --dry-run" do
      described_class.start(%w[purge -y --dry-run])

      expect(a_request(:post, %r{https://neocities\.org/api/delete}))
        .not_to have_been_made
    end

    it "shows help when -y is missing" do
      expect { described_class.start(%w[purge]) }.to raise_error(SystemExit)

      expect(a_request(:post, %r{https://neocities\.org/api/delete}))
        .not_to have_been_made
      expect(a_request(:get, %r{https://neocities\.org/api/list}))
        .not_to have_been_made
    end
  end
end
