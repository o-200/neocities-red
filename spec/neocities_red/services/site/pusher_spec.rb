# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe NeocitiesRed::Services::Site::Pusher do
  subject(:service) do
    described_class.new(
      client,
      display,
      root: root,
      no_gitignore: no_gitignore,
      ignore_dotfiles: ignore_dotfiles,
      exclude: exclude,
      dry_run: dry_run,
      prune: prune,
      optimized: optimized
    )
  end

  let(:client) { instance_double(NeocitiesRed::Client, list: { files: [] }) }
  let(:display) do
    instance_double(
      NeocitiesRed::CliDisplay,
      display_dry_run_notice: nil,
      display_gitignore_hint: nil,
      display_upload_complete: nil,
      display_delete_progress: nil,
      display_delete_success: nil,
      display_delete_error: nil
    )
  end
  let(:no_gitignore) { false }
  let(:ignore_dotfiles) { false }
  let(:exclude) { [] }
  let(:dry_run) { false }
  let(:prune) { false }
  let(:optimized) { false }
  let(:root) { tmp_root }
  let(:uploader_instance) { instance_double(NeocitiesRed::Services::File::File, upload: nil) }
  let(:upload_calls) { [] }

  let(:tmp_root) do
    Dir.mktmpdir("site_pusher_spec").tap do |dir|
      File.write(File.join(dir, "index.html"), "<h1>Hello</h1>")
    end
  end

  before do
    allow(NeocitiesRed::Services::File::File).to receive(:new) do |_client, filepath, remote_path|
      upload_calls << [filepath.to_s, remote_path.to_s]
      uploader_instance
    end
  end

  after do
    FileUtils.rm_rf(tmp_root)
  end

  describe "#push" do
    it "uses .gitignore patterns by default" do
      File.write(File.join(tmp_root, "ignored.txt"), "skip me")
      File.write(File.join(tmp_root, ".gitignore"), "ignored.txt\n")

      service.push

      expect(upload_calls).to include(["index.html", "index.html"])
      expect(upload_calls).not_to include(["ignored.txt", "ignored.txt"])
      expect(display).to have_received(:display_gitignore_hint)
    end

    context "when ignore_dotfiles is enabled" do
      let(:ignore_dotfiles) { true }
      let(:no_gitignore) { true }

      it "does not upload dotfiles" do
        File.write(File.join(tmp_root, ".env"), "SECRET=1")

        service.push

        expect(upload_calls).to include(["index.html", "index.html"])
        expect(upload_calls).not_to include([".env", ".env"])
      end
    end

    context "when optimized is enabled" do
      let(:optimized) { true }
      let(:no_gitignore) { true }

      it "skips files with hashes that already exist remotely" do
        File.write(File.join(tmp_root, "unchanged.txt"), "same content")
        File.write(File.join(tmp_root, "changed.txt"), "new content")
        unchanged_sha = Digest::SHA1.file(File.join(tmp_root, "unchanged.txt")).hexdigest

        allow(client).to receive(:list).and_return(
          files: [
            { path: "unchanged.txt", sha1_hash: unchanged_sha }
          ]
        )

        service.push

        expect(upload_calls).to include(["changed.txt", "changed.txt"])
        expect(upload_calls).not_to include(["unchanged.txt", "unchanged.txt"])
      end
    end

    context "when prune is enabled" do
      let(:prune) { true }
      let(:dry_run) { true }
      let(:no_gitignore) { true }

      it "deletes remote files missing locally and skips children in pruned directories" do
        allow(client).to receive_messages(
          list: {
            files: [
              { path: "missing.txt", is_directory: false },
              { path: "gone_dir", is_directory: true },
              { path: "gone_dir/child.txt", is_directory: false },
              { path: "index.html", is_directory: false }
            ]
          },
          delete_wrapper_with_dry_run: { result: "success" }
        )

        service.push

        expect(client).to have_received(:delete_wrapper_with_dry_run).with("missing.txt", dry_run: true)
        expect(client).to have_received(:delete_wrapper_with_dry_run).with("gone_dir", dry_run: true)
        expect(client).not_to have_received(:delete_wrapper_with_dry_run).with("gone_dir/child.txt", dry_run: true)
      end
    end

    it "raises when root path does not exist" do
      bad_root = File.join(tmp_root, "nope")
      bad_service = described_class.new(
        client,
        display,
        root: bad_root,
        no_gitignore: no_gitignore,
        ignore_dotfiles: ignore_dotfiles,
        exclude: exclude,
        dry_run: dry_run,
        prune: prune,
        optimized: optimized
      )

      expect { bad_service.push }.to raise_error(ArgumentError, /does not exist/)
    end
  end
end
