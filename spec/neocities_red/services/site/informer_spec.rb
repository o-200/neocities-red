# frozen_string_literal: true

require "spec_helper"
require "time"

RSpec.describe NeocitiesRed::Services::Site::Informer do
  let(:client) { instance_double(NeocitiesRed::Client) }
  let(:sitename) { "test-site" }
  let(:subargs) { [] }
  let(:profile_info) { described_class.new(client, subargs, sitename) }
  let(:ansi_escape_regex) { /\e\[[0-9;]*m/ }

  describe "#stats" do
    context "when API returns successful response" do
      let(:response) do
        {
          result: "success",
          info: {
            id: 123,
            sitename: "test-site",
            created_at: "2024-01-01T00:00:00Z",
            last_updated: "2024-01-15T12:00:00Z"
          }
        }
      end

      before do
        allow(client).to receive(:info).with(sitename).and_return(response)
      end

      it "returns the API response" do
        result = profile_info.stats

        expect(result).to eq(response)
      end

      it "calls client.info with the sitename" do
        profile_info.stats

        expect(client).to have_received(:info).with(sitename)
      end
    end

    context "when API returns error response" do
      let(:error_response) do
        {
          result: "error",
          error_type: "site_not_found",
          message: "could not find site nonexistent"
        }
      end

      before do
        allow(client).to receive(:info).and_return(error_response)
      end

      it "raises APIError with the message" do
        expect { profile_info.stats }.to raise_error(
          NeocitiesRed::APIError,
          /could not find site nonexistent/
        )
      end
    end

    context "when subargs are provided" do
      let(:subargs) { ["other-site"] }
      let(:response) { { result: "success", info: { sitename: "other-site" } } }

      before do
        allow(client).to receive(:info).with("other-site").and_return(response)
      end

      it "uses subargs[0] instead of instance sitename" do
        result = profile_info.stats

        expect(result).to eq(response)
        expect(client).to have_received(:info).with("other-site")
      end
    end
  end

  describe "#pretty_print" do
    let(:response) do
      {
        result: "success",
        info: {
          id: 123,
          sitename: "test-site",
          created_at: "2024-01-01T00:00:00Z",
          last_updated: "2024-01-15T12:00:00Z",
          domain: nil
        }
      }
    end

    before do
      allow(client).to receive(:info).and_return(response)
    end

    it "returns an array of key-value pairs" do
      result = profile_info.pretty_print

      expect(result).to be_an(Array)
      expect(result.first).to be_an(Array)
      expect(result.first.first.gsub(ansi_escape_regex, "")).to eq("id")
    end

    it "includes all info keys from the response" do
      result = profile_info.pretty_print

      keys = result.map { |pair| pair.first.gsub(ansi_escape_regex, "") }
      expect(keys).to include("id", "sitename", "created_at", "last_updated", "domain")
    end

    it "bolds the keys" do
      pastel = object_double(Pastel.new(eachline: "\n"))
      allow(Pastel).to receive(:new).with(eachline: "\n").and_return(pastel)
      allow(pastel).to receive(:bold) { |msg| "BOLD(#{msg})" }
      allow(client).to receive(:info).and_return(response)

      result = profile_info.pretty_print

      expect(result.first.first).to eq("BOLD(id)")
    end

    context "when created_at is present" do
      it "parses created_at into a Time object" do
        result = profile_info.pretty_print

        created_at_pair = result.find { |pair| pair.first.gsub(ansi_escape_regex, "") == "created_at" }
        expect(created_at_pair.last).to be_a(Time)
      end
    end

    context "when last_updated is present" do
      it "parses last_updated into a Time object" do
        result = profile_info.pretty_print

        last_updated_pair = result.find { |pair| pair.first.gsub(ansi_escape_regex, "") == "last_updated" }
        expect(last_updated_pair.last).to be_a(Time)
      end
    end
  end

  describe "#initialize" do
    it "stores the client" do
      expect(profile_info.client).to eq(client)
    end

    it "stores the subargs" do
      expect(profile_info.instance_variable_get(:@subargs)).to eq(subargs)
    end

    it "stores the sitename" do
      expect(profile_info.instance_variable_get(:@sitename)).to eq(sitename)
    end

    it "creates a Pastel instance" do
      expect(profile_info.instance_variable_get(:@pastel)).to be_a(Pastel::Delegator)
    end

    context "when subargs is nil" do
      let(:subargs) { nil }

      it "handles nil subargs" do
        profile = described_class.new(client, nil, sitename)
        expect(profile.instance_variable_get(:@subargs)).to be_nil
      end
    end

    context "when sitename is nil" do
      let(:sitename) { nil }

      it "handles nil sitename" do
        profile = described_class.new(client, subargs, nil)
        expect(profile.instance_variable_get(:@sitename)).to be_nil
      end
    end
  end
end
