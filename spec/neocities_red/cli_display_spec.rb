# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe NeocitiesRed::CliDisplay do
  let(:io) { StringIO.new }
  let(:display) { described_class.new(io: io) }

  def text_output
    io.string.gsub(/\e\[[\d;]*m/, "")
  end

  describe "#say" do
    it "writes a message to output" do
      display.say("hello")

      expect(text_output).to include("hello")
    end
  end

  describe "#display_response" do
    it "prints success responses" do
      display.display_response(result: "success", message: "uploaded")

      expect(text_output).to include("SUCCESS: uploaded")
    end

    it "prints file exists responses" do
      display.display_response(
        result: "error",
        message: "already there",
        error_type: "file_exists"
      )

      expect(text_output).to include("EXISTS: already there (file_exists)")
    end

    it "prints generic error responses" do
      display.display_response(
        result: "error",
        message: "nope",
        error_type: "denied"
      )

      expect(text_output).to include("ERROR: nope (denied)")
    end

    it "prints exception details and exits" do
      expect { display.display_response(StandardError.new("boom")) }
        .to raise_error(SystemExit)

      expect(text_output).to include("ERROR:")
      expect(text_output).to include("boom")
    end
  end

  describe "#display_diff_results" do
    it "prints all diff sections that have items" do
      display.display_diff_results(
        added: ["new.txt"],
        modified: ["changed.txt"],
        removed: ["old.txt"]
      )

      expect(text_output).to include(
        "Removed files",
        "old.txt",
        "Modified files",
        "changed.txt",
        "New files",
        "new.txt"
      )
    end

    it "prints nothing when there are no changes" do
      display.display_diff_results(added: [], modified: [], removed: [])

      expect(text_output).to eq("")
    end
  end

  describe "status helpers" do
    it "prints delete progress and success on the same line" do
      display.display_delete_progress("foo.txt")
      display.display_delete_success

      expect(text_output).to include("Deleting foo.txt ... SUCCESS")
    end

    it "prints delete errors via display_response" do
      display.display_delete_error(result: "error", message: "failed")

      expect(text_output).to include("ERROR: failed")
    end
  end

  describe "help and banner output" do
    it "prints banner" do
      display.display_banner

      expect(text_output).to include("Neocities red")
      expect(text_output).to include("|\\---/|")
    end

    it "prints pizza text and exits" do
      pizza = instance_double(NeocitiesRed::Services::Common::Pizza, make_order: "pizza unavailable")
      allow(NeocitiesRed::Services::Common::Pizza).to receive(:new).and_return(pizza)

      expect { display.display_pizza_help_and_exit }.to raise_error(SystemExit)
      expect(text_output).to include("pizza unavailable")
    end

    {
      display_list_help_and_exit: "list - List files on your Neocities site",
      display_delete_help_and_exit: "delete - Delete files on your Neocities site",
      display_upload_help_and_exit: "upload - Upload a file/folder to a path on your Neocities site",
      display_pull_help_and_exit: "pull - Get the most recent version of files from your site",
      display_push_help_and_exit: "push - Recursively upload a local directory to your Neocities site",
      display_diff_help_and_exit: "diff - Compare local files with remote and show differences.",
      display_info_help_and_exit: "info - Get site info",
      display_logout_help_and_exit: "logout - Remove the site api key from the config",
      display_help_and_exit: "Subcommands:"
    }.each do |method_name, expected_text|
      it "prints #{method_name} and exits" do
        expect { display.public_send(method_name) }.to raise_error(SystemExit)

        expect(text_output).to include("Neocities red")
        expect(text_output).to include(expected_text)
      end
    end
  end
end
