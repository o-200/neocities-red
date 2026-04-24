# frozen_string_literal: true

require File.join(File.dirname(__FILE__), "neocities_red", "version")
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
require File.join(File.dirname(__FILE__), "neocities_red", "services", "common", "pizza")
