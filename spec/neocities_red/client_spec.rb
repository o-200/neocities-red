# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe NeocitiesRed::Client do
  let(:api_key) { "test_api_key" }
  let(:sitename) { "test-site" }
  let(:password) { "test_password" }

  describe "#initialize" do
    it "raises an error without authentication" do
      expect { described_class.new }.to raise_error(ArgumentError, /client requires a login/)
    end

    it "initializes with an API key" do
      client = described_class.new(api_key: api_key)
      expect(client).to be_a(described_class)
    end

    it "initializes with sitename and password" do
      client = described_class.new(sitename: sitename, password: password)
      expect(client).to be_a(described_class)
    end
  end

  describe "#key" do
    let(:client) { described_class.new(sitename: sitename, password: password) }
    let(:mock_response) { { api_key: "test_key_123" } }
    let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:get).and_return(mock_conn_response)
    end

    it "retrieves the API key from the response" do
      response = client.key
      expect(response[:api_key]).to eq("test_key_123")
    end
  end

  describe "#list" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:mock_response) { { result: "success", files: [{ path: "test.txt", is_directory: false }] } }
    let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:get).and_return(mock_conn_response)
    end

    it "lists files in the root directory" do
      response = client.list
      expect(response[:result]).to eq("success")
      expect(response[:files]).to be_an(Array)
      expect(response[:files].first[:path]).to eq("test.txt")
    end

    it "lists files in a specific path" do
      response = client.list("/test")
      expect(response[:result]).to eq("success")
    end
  end

  describe "#info" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:mock_response) do
      {
        result: "success",
        info: {
          created_at: "2024-01-01T00:00:00Z",
          last_updated: "2024-01-02T00:00:00Z",
          domain: nil
        }
      }
    end
    let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:get).and_return(mock_conn_response)
    end

    it "retrieves site info" do
      response = client.info(sitename)
      expect(response[:result]).to eq("success")
      expect(response[:info]).to be_a(Hash)
      expect(response[:info][:created_at]).to eq("2024-01-01T00:00:00Z")
    end

    it "returns error response for non-existent site" do
      error_response = { result: "error", message: "Site not found" }
      allow(client.instance_variable_get(:@conn)).to receive(:get)
        .and_return(instance_double(Faraday::Response, body: error_response.to_json))

      response = client.info("nonexistent-site")
      expect(response[:result]).to eq("error")
    end
  end

  describe "#get" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:mock_response) { { result: "success" } }
    let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:get).and_return(mock_conn_response)
    end

    it "makes a GET request to the API" do
      response = client.get("list")
      expect(response).to be_a(Hash)
      expect(response[:result]).to eq("success")
    end

    it "passes parameters to the API" do
      response = client.get("list", path: "/test")
      expect(response[:result]).to eq("success")
    end
  end

  describe "#post" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:mock_response) { { result: "success" } }
    let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:post).and_return(mock_conn_response)
    end

    it "makes a POST request to the API" do
      response = client.post("list")
      expect(response).to be_a(Hash)
      expect(response[:result]).to eq("success")
    end
  end

  describe "#upload_hash" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:remote_path) { "test.txt" }
    let(:sha1_hash) { "da39a3ee5e6b4b0d3255bfef95601890afd80709" }
    let(:mock_response) { { result: "success", files: {} } }
    let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:post).and_return(mock_conn_response)
    end

    it "checks if file exists by hash" do
      response = client.upload_hash(remote_path, sha1_hash)
      expect(response).to be_a(Hash)
      expect(response[:result]).to eq("success")
    end
  end

  describe "#upload" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:temp_dir) { Dir.mktmpdir }
    let(:test_file) { File.join(temp_dir, "test_upload.txt") }

    before do
      File.write(test_file, "test content")
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context "when file does not exist" do
      it "raises an error for non-existent file" do
        expect { client.upload("/nonexistent/file.txt") }.to raise_error(ArgumentError)
      end
    end

    context "when file exists" do
      let(:mock_response) { { result: "success", message: "File uploaded" } }
      let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

      before do
        allow(client).to receive(:upload_hash).and_return({ result: "success", files: {} })
        allow(client.instance_variable_get(:@conn)).to receive(:post).and_return(mock_conn_response)
      end

      it "uploads a file" do
        response = client.upload(test_file, "test_upload.txt")
        expect(response[:result]).to eq("success")
      end

      it "supports dry run mode" do
        response = client.upload(test_file, "test_upload.txt", dry_run: true)
        expect(response[:result]).to eq("success")
      end

      context "when file already exists on server with same hash" do
        let(:mock_hash_response) { { result: "success", files: { "test_upload.txt" => true } } }

        before do
          allow(client).to receive(:upload_hash).and_return(mock_hash_response)
        end

        it "returns file_exists error without uploading" do
          response = client.upload(test_file, "test_upload.txt")
          expect(response[:result]).to eq("error")
          expect(response[:error_type]).to eq("file_exists")
        end
      end
    end
  end

  describe "#delete" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:mock_response) { { result: "success", message: "File deleted" } }
    let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:post).and_return(mock_conn_response)
    end

    it "deletes a file" do
      response = client.delete("test_delete.txt")
      expect(response).to be_a(Hash)
      expect(response[:result]).to eq("success")
    end

    it "deletes multiple files" do
      response = client.delete("test1.txt", "test2.txt")
      expect(response[:result]).to eq("success")
    end
  end

  describe "#delete_wrapper_with_dry_run" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:mock_response) { { result: "success", message: "File deleted" } }
    let(:mock_conn_response) { instance_double(Faraday::Response, body: mock_response.to_json) }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:post).and_return(mock_conn_response)
    end

    it "returns success without making request in dry run mode" do
      response = client.delete_wrapper_with_dry_run("test.txt", dry_run: true)
      expect(response[:result]).to eq("success")
    end

    it "calls delete when not in dry run mode" do
      response = client.delete_wrapper_with_dry_run("test.txt", dry_run: false)
      expect(response[:result]).to eq("success")
    end
  end

  describe "#download" do
    let(:client) { described_class.new(api_key: api_key) }
    let(:mock_conn_response) { instance_double(Faraday::Response, status: 200, body: "raw content") }

    before do
      allow(client.instance_variable_get(:@conn)).to receive(:get).and_return(mock_conn_response)
    end

    it "returns the raw Faraday response for a url" do
      response = client.download("https://example.com/index.html")
      expect(response).to eq(mock_conn_response)
    end
  end
end
