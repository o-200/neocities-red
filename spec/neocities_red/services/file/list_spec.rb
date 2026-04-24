# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe NeocitiesRed::Services::File::List do
  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:path) { nil }
  let(:detail) { false }
  let(:file_list) { described_class.new(client, path, detail) }

  describe "#list" do
    context "when successful" do
      let(:files_response) do
        {
          result: "success",
          files: [
            { path: "index.html", is_directory: false, size: 1024, sha1_hash: "abc123", updated_at: "2024-01-01T00:00:00Z" },
            { path: "images/", is_directory: true, size: nil, sha1_hash: nil, updated_at: "2024-01-01T00:00:00Z" }
          ]
        }
      end

      before do
        allow(client).to receive(:list).with(path).and_return(files_response)
      end

      it "returns an array of files" do
        result = file_list.list

        expect(result).to eq(files_response[:files])
      end

      it "calls client.list with the correct path" do
        file_list.list

        expect(client).to have_received(:list).with(path)
      end
    end

    context "when given a specific path" do
      let(:path) { "/test" }
      let(:files_response) { { result: "success", files: [{ path: "test.html", is_directory: false }] } }

      before do
        allow(client).to receive(:list).with(path).and_return(files_response)
      end

      it "returns files from the specified path" do
        result = file_list.list

        expect(result).to eq(files_response[:files])
      end
    end

    context "when API returns an error" do
      let(:error_response) { { result: "error", message: "Invalid path" } }

      before do
        allow(client).to receive(:list).and_return(error_response)
        allow($stdout).to receive(:puts)
      end

      it "displays the error and exits" do
        expect { file_list.list }.to raise_error(SystemExit)
      end
    end
  end

  describe "#show" do
    context "when successful without detail" do
      let(:files_response) do
        {
          result: "success",
          files: [
            { path: "index.html", is_directory: false, size: 1024, sha1_hash: "abc123", updated_at: "2024-01-01T00:00:00Z" },
            { path: "images/", is_directory: true, size: nil, sha1_hash: nil, updated_at: "2024-01-01T00:00:00Z" }
          ]
        }
      end

      before do
        allow(client).to receive(:list).with(path).and_return(files_response)
        allow($stdout).to receive(:puts)
      end

      it "returns an array of files" do
        result = file_list.show

        expect(result).to eq(files_response[:files])
      end

      it "does not print table when detail is false" do
        allow(TTY::Table).to receive(:new)

        file_list.show

        expect(TTY::Table).not_to have_received(:new)
      end
    end

    context "when successful with detail" do
      let(:detail) { true }
      let(:files_response) do
        {
          result: "success",
          files: [
            { path: "index.html", is_directory: false, size: 1024, sha1_hash: "abc123", updated_at: "2024-01-01T00:00:00Z" }
          ]
        }
      end
      let(:pastel) { object_double(Pastel.new(eachline: "\n")) }
      let(:table) { instance_double(TTY::Table) }

      before do
        allow(client).to receive(:list).with(path).and_return(files_response)
        allow(Pastel).to receive(:new).with(eachline: "\n").and_return(pastel)
        allow(pastel).to receive(:bold) { |msg| "BOLD(#{msg})" }
        allow(pastel).to receive_messages(blue: pastel, green: pastel)
        allow(TTY::Table).to receive(:new).and_return(table)
        allow(table).to receive(:to_s).and_return("table output")
        allow($stdout).to receive(:puts)
      end

      it "returns files with detailed information" do
        result = file_list.show

        expect(result).to eq(files_response[:files])
      end

      it "prints a table with detailed information" do
        file_list.show

        expect(TTY::Table).to have_received(:new).with(array_including(
                                                         include("BOLD(Path)", "BOLD(Size)",
                                                                 "BOLD(sha1_Hash)", "BOLD(Updated)")
                                                       ))
      end

      it "colors directories blue and files green" do
        file_list.show

        expect(pastel).to have_received(:green).at_least(:once)
      end
    end

    context "when API returns an error" do
      let(:error_response) { { result: "error", message: "Path not found" } }

      before do
        allow(client).to receive(:list).and_return(error_response)
        allow($stdout).to receive(:puts)
      end

      it "displays the error and exits" do
        expect { file_list.show }.to raise_error(SystemExit)
      end
    end
  end

  describe "#initialize" do
    it "creates an instance with client, path, and detail" do
      expect(file_list.instance_variable_get(:@client)).to eq(client)
      expect(file_list.instance_variable_get(:@path)).to eq(path)
      expect(file_list.instance_variable_get(:@detail)).to eq(detail)
    end

    it "handles nil detail as false" do
      file_list_nil_detail = described_class.new(client, path, nil)
      expect(file_list_nil_detail.instance_variable_get(:@detail)).to be(false)
    end

    it "creates a Pastel instance" do
      expect(file_list.instance_variable_get(:@pastel)).to be_a(Pastel::Delegator)
    end
  end
end
