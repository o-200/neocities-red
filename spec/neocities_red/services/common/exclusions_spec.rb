# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe NeocitiesRed::Services::Common::Exclusions do
  let(:tmp_root) { Dir.mktmpdir("exclusions_spec") }

  before do
    FileUtils.mkdir_p(File.join(tmp_root, "node_modules"))
    File.write(File.join(tmp_root, "node_modules", "dep.js"), "x")
    File.write(File.join(tmp_root, "secret.txt"), "x")
    File.write(File.join(tmp_root, "keep.txt"), "x")
  end

  after do
    FileUtils.rm_rf(tmp_root)
  end

  describe ".build" do
    it "returns an empty list for entries that do not exist" do
      expect(described_class.build([File.join(tmp_root, "nope")])).to eq([])
    end

    it "returns the path for an existing file" do
      expect(described_class.build([File.join(tmp_root, "secret.txt")]))
        .to eq([File.join(tmp_root, "secret.txt")])
    end

    it "returns the directory and all of its children for an existing directory" do
      entries = described_class.build([File.join(tmp_root, "node_modules")])

      expect(entries).to include(File.join(tmp_root, "node_modules"))
      expect(entries).to include(File.join(tmp_root, "node_modules", "dep.js"))
    end

    it "normalizes paths relative to base_path when given" do
      entries = described_class.build(
        [File.join(tmp_root, "secret.txt"), File.join(tmp_root, "node_modules")],
        base_path: tmp_root
      )

      expect(entries).to contain_exactly("secret.txt", "node_modules", "node_modules/dep.js")
    end
  end
end
