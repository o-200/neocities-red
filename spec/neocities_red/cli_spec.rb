# frozen_string_literal: true

require "spec_helper"

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
        File.join("C:/Users/alice", "Local Settings", "Application Data", app_name)
      )
    end

    it "uses ~/.neocities on freebsd" do
      stub_const("RUBY_PLATFORM", "amd64-freebsd14")
      allow(Dir).to receive(:home).and_return("/home/alice")

      path = described_class.app_config_path(app_name)
      expect(path).to eq(File.join("/home/alice", ".#{app_name}"))
    end
  end
end
