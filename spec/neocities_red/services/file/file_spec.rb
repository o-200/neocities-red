# frozen_string_literal: true

require "fileutils"
require "spec_helper"

RSpec.describe NeocitiesRed::Services::File::File do
  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:filepath) { "/path/to/file.txt" }
  let(:remote_path) { "file.txt" }
  let(:uploader) { described_class.new(client, filepath, remote_path) }

  describe "#upload" do
    context "when the file does not exist" do
      before do
        allow(Pathname).to receive(:new).with(filepath).and_return(instance_double(Pathname, exist?: false))
      end

      it "raises FileIsNotExists error" do
        expect { uploader.upload }.to raise_error(
          NeocitiesRed::Services::File::FileIsNotExists,
          /does not exist locally/
        )
      end
    end

    context "when the path is a directory" do
      let(:path_double) { instance_double(Pathname, exist?: true, directory?: true, to_s: filepath) }

      before do
        allow(Pathname).to receive(:new).with(filepath).and_return(path_double)
        allow(client).to receive(:upload)
        allow($stdout).to receive(:puts)
      end

      it "prints a message and returns without uploading" do
        uploader.upload

        expect($stdout).to have_received(:puts).with(match(/#{Regexp.escape(filepath)} is a directory, skipping/))
        expect(client).not_to have_received(:upload)
      end
    end

    context "when the file exists and is not a directory" do
      let(:path_double) { instance_double(Pathname, exist?: true, directory?: false, to_s: filepath) }
      let(:success_response) { { result: "success", message: "File uploaded successfully" } }

      before do
        allow(Pathname).to receive(:new).with(filepath).and_return(path_double)
        allow($stdout).to receive(:puts)
      end

      context "when upload is successful" do
        before do
          allow(client).to receive(:upload).with(path_double, remote_path).and_return(success_response)
        end

        it "calls client.upload with the file and remote path" do
          uploader.upload

          expect(client).to have_received(:upload).with(path_double, remote_path)
        end

        it "prints success message" do
          uploader.upload

          expect($stdout).to have_received(:puts).with(/SUCCESS/)
        end

        it "returns the success response" do
          result = uploader.upload

          expect(result).to eq(success_response)
        end
      end

      context "when file already exists on server" do
        let(:exists_response) do
          {
            result: "error",
            error_type: "file_exists",
            message: "file already exists and matches local file, not uploading"
          }
        end

        before do
          allow(client).to receive(:upload).with(path_double, remote_path).and_return(exists_response)
        end

        it "prints exists message" do
          uploader.upload

          expect($stdout).to have_received(:puts).with(/EXISTS/)
        end

        it "returns the error response" do
          result = uploader.upload

          expect(result).to eq(exists_response)
        end
      end

      context "when upload fails with other error" do
        let(:error_response) do
          { result: "error", error_type: "upload_failed", message: "Upload failed" }
        end

        before do
          allow(client).to receive(:upload).with(path_double, remote_path).and_return(error_response)
        end

        it "prints error message" do
          uploader.upload

          expect($stdout).to have_received(:puts).with(
            hash_including(result: "error", error_type: "upload_failed", message: "Upload failed")
          )
        end

        it "returns the error response" do
          result = uploader.upload

          expect(result).to eq(error_response)
        end
      end
    end

    context "with custom remote path" do
      let(:custom_remote_path) { "custom/path/file.txt" }
      let(:path_double) { instance_double(Pathname, exist?: true, directory?: false, to_s: filepath) }
      let(:custom_uploader) { described_class.new(client, filepath, custom_remote_path) }
      let(:success_response) { { result: "success", message: "File uploaded successfully" } }

      before do
        allow(Pathname).to receive(:new).with(filepath).and_return(path_double)
        allow(client).to receive(:upload).with(path_double, custom_remote_path).and_return(success_response)
        allow($stdout).to receive(:puts)
      end

      it "uses the custom remote path" do
        custom_uploader.upload

        expect(client).to have_received(:upload).with(path_double, custom_remote_path)
      end
    end
  end

  describe "#initialize" do
    it "stores the client, filepath, and remote_path" do
      expect(uploader.instance_variable_get(:@client)).to eq(client)
      expect(uploader.instance_variable_get(:@filepath)).to eq(filepath)
      expect(uploader.instance_variable_get(:@remote_path)).to eq(remote_path)
    end

    it "creates a Pastel instance" do
      expect(uploader.instance_variable_get(:@pastel)).to be_a(Pastel::Delegator)
    end
  end
end
