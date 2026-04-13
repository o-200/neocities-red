# spec/neocities_red/services/site_difference_spec.rb
# frozen_string_literal: true

require "spec_helper"
require "digest"
require "pathname"
require "pastel"

RSpec.describe NeocitiesRed::Services::SiteDifference do
  subject(:service) do
    described_class.new(
      client,
      path: path,
      detail: detail,
      ignore_dotfiles: ignore_dotfiles,
      exclude: exclude
    )
  end

  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:path) { "/tmp/site" }
  let(:detail) { false }
  let(:ignore_dotfiles) { false }
  let(:exclude) { [] }

  # rubocop:disable RSpec/VerifiedDoubles
  let(:pastel) { double("Pastel") }
  # rubocop:enable RSpec/VerifiedDoubles

  let(:file_list_service) do
    instance_double(
      NeocitiesRed::Services::FileList,
      show: server_files
    )
  end

  before do
    allow(Pastel).to receive(:new).with(eachline: "\n").and_return(pastel)

    allow(NeocitiesRed::Services::FileList).to receive(:new)
      .and_return(file_list_service)

    allow(Dir).to receive(:chdir).with(Pathname(path)).and_yield

    allow(pastel).to receive(:green) { |value| "GREEN(#{value})" }
    allow(pastel).to receive(:yellow) { |value| "YELLOW(#{value})" }
    allow(pastel).to receive(:red) { |value| "RED(#{value})" }
  end

  describe "#show" do
    let(:server_files) do
      [
        { path: "index.html", sha1_hash: "server-index-sha" },
        { path: "about.html", sha1_hash: "server-about-sha" },
        { path: "old.html", sha1_hash: "server-old-sha" }
      ]
    end

    let(:globbed_paths) do
      [
        "index.html",
        "about.html",
        "contact.html",
        "assets",
        ".git",
        ".env"
      ]
    end

    before do
      allow(Dir).to receive(:glob)
        .with(File.join("**", "*"), File::FNM_DOTMATCH)
        .and_return(globbed_paths)

      allow(File).to receive(:file?).with("index.html").and_return(true)
      allow(File).to receive(:file?).with("about.html").and_return(true)
      allow(File).to receive(:file?).with("contact.html").and_return(true)
      allow(File).to receive(:file?).with("assets").and_return(false)

      allow(Digest::SHA1).to receive(:file).with("index.html")
                                           .and_return(instance_double(Digest::SHA1, hexdigest: "server-index-sha"))
      allow(Digest::SHA1).to receive(:file).with("about.html")
                                           .and_return(instance_double(Digest::SHA1, hexdigest: "local-about-sha"))
      allow(Digest::SHA1).to receive(:file).with("contact.html")
                                           .and_return(instance_double(Digest::SHA1, hexdigest: "local-contact-sha"))
    end

    it "returns added, modified and removed paths" do
      added_paths, modified_paths, removed_paths = service.show

      expect(added_paths).to eq(["GREEN(contact.html)", "GREEN(assets)"])
      expect(modified_paths).to eq(["YELLOW(about.html)"])
      expect(removed_paths).to eq(["RED(old.html)"])
    end

    it "requests server files with FileList service" do
      service.show

      expect(NeocitiesRed::Services::FileList).to have_received(:new)
        .with(client, nil, detail)
      expect(file_list_service).to have_received(:show)
    end

    it "hashes only local files, not directories" do
      service.show

      expect(Digest::SHA1).to have_received(:file).with("index.html")
      expect(Digest::SHA1).to have_received(:file).with("about.html")
      expect(Digest::SHA1).to have_received(:file).with("contact.html")
      expect(Digest::SHA1).not_to have_received(:file).with("assets")
    end

    it "always excludes dotfiles and dot-directories from local paths" do
      added_paths, = service.show

      expect(added_paths).not_to include("GREEN(.git)")
      expect(added_paths).not_to include("GREEN(.env)")
    end

    context "when exclude is provided" do
      let(:exclude) { ["contact.html", "old.html"] }

      it "excludes paths from diff" do
        added_paths, modified_paths, removed_paths = service.show

        expect(added_paths).to eq(["GREEN(assets)"])
        expect(modified_paths).to eq(["YELLOW(about.html)"])
        expect(removed_paths).to eq([])
      end
    end

    context "when ignore_dotfiles is true" do
      let(:ignore_dotfiles) { true }

      it "still returns the same result because dotfiles are already filtered earlier" do
        added_paths, modified_paths, removed_paths = service.show

        expect(added_paths).to eq(["GREEN(contact.html)", "GREEN(assets)"])
        expect(modified_paths).to eq(["YELLOW(about.html)"])
        expect(removed_paths).to eq(["RED(old.html)"])
      end
    end
  end

  describe "#initialize" do
    let(:detail) { nil }
    let(:server_files) { [] }

    before do
      allow(Dir).to receive(:glob)
        .with(File.join("**", "*"), File::FNM_DOTMATCH)
        .and_return([])
    end

    it "sets detail to false when nil is passed" do
      service.show

      expect(NeocitiesRed::Services::FileList).to have_received(:new)
        .with(client, nil, false)
    end
  end
end
