# frozen_string_literal: true

require "spec_helper"
require "fileutils"

RSpec.describe NeocitiesRed::Services::FolderUploader do
  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:remote_path) { "ext/" }

  let(:spec_root) { File.expand_path("..", __dir__) } # => ./spec
  let(:tmp_root)  { File.join(spec_root, "tmp", "folder_uploader_spec") }

  def write_file(rel_path, content: "x")
    abs = File.join(tmp_root, rel_path)
    FileUtils.mkdir_p(File.dirname(abs))
    File.write(abs, content)
    abs
  end

  around do |example|
    FileUtils.rm_rf(tmp_root)
    FileUtils.mkdir_p(tmp_root)
    example.run
  ensure
    FileUtils.rm_rf(tmp_root)
  end

  describe "#files" do
    it "raises FileIsNotExists when the path does not exist" do
      uploader = described_class.new(client, File.join(tmp_root, "nope"), remote_path)
      expect { uploader.files }.to raise_error(NeocitiesRed::Services::FileIsNotExists)
    end

    it "returns all files under the directory as relative paths, including dotfiles, excluding directories" do
      write_file("ext/a.txt")
      write_file("ext/sub/b.txt")
      write_file("ext/.env")
      write_file("ext/sub/.keep")

      FileUtils.mkdir_p(File.join(tmp_root, "ext/empty_dir"))
      FileUtils.mkdir_p(File.join(tmp_root, "ext/.hiddendir"))

      uploader = described_class.new(client, File.join(tmp_root, "ext"), remote_path)
      expect(uploader.files).to contain_exactly("a.txt", "sub/b.txt", ".env", "sub/.keep")
    end

    it "accepts a relative directory path and returns files relative to that directory" do
      write_file("tmp_ext/root.rb", content: "puts :ok")
      write_file("tmp_ext/sub/nested.rb", content: "puts :ok")

      Dir.chdir(tmp_root) do
        uploader = described_class.new(client, "./tmp_ext/", remote_path)
        expect(uploader.files).to contain_exactly("root.rb", "sub/nested.rb")
      end
    end

    it "returns nil when filepath is a file (not a directory)" do
      file_path = write_file("not_a_dir.txt", content: "hello")
      uploader = described_class.new(client, file_path, remote_path)

      expect(uploader.files).to be_nil
    end
  end
end
