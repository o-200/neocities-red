# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe NeocitiesRed::Services::File::Remover do
  subject(:remover) { described_class.new(client, filepath) }

  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:filepath) { "test_file.txt" }
  let(:io) { StringIO.new }
  let(:pastel) { object_double(Pastel.new(eachline: "\n")) }

  before do
    allow(Pastel).to receive(:new).with(eachline: "\n").and_return(pastel)
    allow(pastel).to receive(:bold) { |msg| msg }
    allow(pastel).to receive_messages(green: pastel, yellow: pastel)
    allow($stdout).to receive_messages(puts: nil, print: nil)
  end

  describe "#initialize" do
    it "stores the client instance" do
      expect(remover.client).to eq(client)
    end

    it "stores the filepath" do
      expect(remover.filepath).to eq(filepath)
    end

    it "allows filepath to be reassigned" do
      remover.filepath = "new_file.txt"
      expect(remover.filepath).to eq("new_file.txt")
    end
  end

  describe "#remove" do
    context "when deletion is successful" do
      let(:success_response) { { result: "success", message: "File deleted successfully" } }

      before do
        allow(client).to receive(:delete).with(filepath).and_return(success_response)
      end

      it "calls client.delete with the filepath" do
        remover.remove
        expect(client).to have_received(:delete).with(filepath)
      end

      it "prints deletion progress message" do
        remover.remove
        expect(pastel).to have_received(:bold).with("Deleting #{filepath} ...")
      end

      it "prints SUCCESS message" do
        remover.remove
        expect(pastel).to have_received(:green)
      end

      it "returns the success response" do
        response = remover.remove
        expect(response).to eq(success_response)
      end
    end

    context "when file does not exist" do
      let(:error_response) do
        { result: "error", message: "File not found", error_type: "not_found" }
      end

      before do
        allow(client).to receive(:delete).with(filepath).and_return(error_response)
      end

      it "calls client.delete with the filepath" do
        remover.remove
        expect(client).to have_received(:delete).with(filepath)
      end

      it "prints error message" do
        remover.remove
        expect(pastel).to have_received(:bold).with("File not found")
      end

      it "returns the error response" do
        response = remover.remove
        expect(response).to eq(error_response)
      end
    end

    context "when file already exists error type" do
      let(:exists_response) do
        { result: "error", message: "File exists", error_type: "file_exists" }
      end

      before do
        allow(client).to receive(:delete).with(filepath).and_return(exists_response)
      end

      it "prints EXISTS message" do
        remover.remove
        expect(pastel).to have_received(:yellow)
      end

      it "returns the error response" do
        response = remover.remove
        expect(response).to eq(exists_response)
      end
    end

    context "with different filepaths" do
      let(:another_filepath) { "images/photo.jpg" }
      let(:success_response) { { result: "success", message: "Deleted" } }

      before do
        allow(client).to receive(:delete).with(another_filepath).and_return(success_response)
      end

      it "works with nested paths" do
        remover.filepath = another_filepath
        remover.remove
        expect(client).to have_received(:delete).with(another_filepath)
      end
    end
  end
end
