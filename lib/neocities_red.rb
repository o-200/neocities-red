# frozen_string_literal: true

# Top-level namespace for the NeocitiesRed gem.
#
# Provides a CLI tool and Ruby API client for managing static sites
# hosted on {https://neocities.org Neocities.org}.
#
# @see NeocitiesRed::Client HTTP API client
# @see NeocitiesRed::CLI Command-line interface
module NeocitiesRed
  # Service layer organized by domain.
  #
  # - {Services::File} — single-file and folder-level operations (upload, delete, list)
  # - {Services::Site} — site-level operations (push, diff, info, export)
  # - {Services::Common} — shared utilities (exclusions, worker pool)
  module Services; end

  require File.join(File.dirname(__FILE__), "neocities_red", "version")
  require File.join(File.dirname(__FILE__), "neocities_red", "errors")
  require File.join(File.dirname(__FILE__), "neocities_red", "client")
  require File.join(File.dirname(__FILE__), "neocities_red", "cli_display")
  require File.join(File.dirname(__FILE__), "neocities_red", "cli")

  require File.join(File.dirname(__FILE__), "neocities_red", "services", "file", "uploader")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "file", "folder_uploader")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "file", "remover")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "file", "list")

  require File.join(File.dirname(__FILE__), "neocities_red", "services", "site", "differencer")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "site", "informer")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "site", "exporter")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "site", "pusher")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "common", "exclusions")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "common", "worker_pool")
  require File.join(File.dirname(__FILE__), "neocities_red", "services", "common", "pizza")
end
