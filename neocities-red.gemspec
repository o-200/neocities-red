# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "neocities_red/version"

Gem::Specification.new do |spec|
  spec.name          = "neocities-red"
  spec.version       = NeocitiesRed::VERSION
  spec.authors       = ["Kyle Drake", "o-200"]
  spec.summary       = "Yet Another Neocities.org CLI and API client with improvements"
  spec.homepage      = "https://github.com/o-200/neocities-red"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    files = begin
      if system("git", "rev-parse", "--is-inside-work-tree", out: File::NULL, err: File::NULL)
        `git ls-files -z`.split("\x0").reject { |f| f == ".yardopts" }
      else
        []
      end
    rescue Errno::ENOENT
      []
    end

    if files.empty?
      files = Dir.glob("**/*", File::FNM_DOTMATCH).select do |path|
        File.file?(path) &&
          !path.start_with?("test/", "spec/", "features/", ".git/", ".github/", ".rubocop_cache/") &&
            path != ".yardopts"
      end
    end

    files
  end

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/mkrf_conf.rb"]
  spec.required_ruby_version = ">= 3.4.0"

  spec.add_dependency "faraday", "~> 2.14.3"
  spec.add_dependency "faraday-follow_redirects"
  spec.add_dependency "faraday-multipart"
  spec.add_dependency "faraday-retry"
  spec.add_dependency "fiddle"
  spec.add_dependency "pastel", "~> 0.8", "= 0.8.0"
  spec.add_dependency "rake", "~> 13", ">= 13.3.0"
  spec.add_dependency "thor", "~> 1.5.0", ">= 1.5.0"
  spec.add_dependency "tty-prompt", "~> 0.23", "= 0.23.1"
  spec.add_dependency "tty-table", "~> 0.12", "= 0.12.0"
  spec.add_dependency "whirly", "~> 0.3", ">= 0.3.0"

  spec.metadata["rubygems_mfa_required"] = "true"
end
