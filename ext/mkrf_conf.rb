# frozen_string_literal: true

require "rubygems"
require "rubygems/command"
require "rubygems/dependency_installer"
begin
  Gem::Command.build_args = ARGV
rescue NoMethodError => e
  warn "Gem::Command.build_args= not available: #{e.message}"
end
inst = Gem::DependencyInstaller.new
begin
  inst.install "openssl-win-root", "~> 1.1" if Gem.win_platform?
rescue StandardError
  exit(1)
end

# create dummy rakefile to indicate success
File.write(File.join(File.dirname(__FILE__), "Rakefile"), "task :default\n")
