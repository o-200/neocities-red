# frozen_string_literal: true

require "spec_helper"

RSpec.describe NeocitiesRed::Services::File::Remover do
  subject(:remover) { described_class.new(client, filepath, display: display) }

  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:filepath) { "test_file.txt" }
  let(:display) do
    instance_double(
      NeocitiesRed::CliDisplay,
      display_delete_progress: nil,
      display_delete_success: nil,
      display_delete_error: nil
    )
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

      it "displays delete progress and success" do
        remover.remove
        expect(display).to have_received(:display_delete_progress).with(filepath)
        expect(display).to have_received(:display_delete_success)
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

      it "displays delete error" do
        remover.remove
        expect(display).to have_received(:display_delete_error).with(error_response)
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

      it "displays delete error" do
        remover.remove
        expect(display).to have_received(:display_delete_error).with(exists_response)
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
