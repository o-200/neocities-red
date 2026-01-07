# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'neocities/version'

Gem::Specification.new do |spec|
  spec.name          = 'neocities-red'
  spec.version       = Neocities::VERSION
  spec.authors       = ['Kyle Drake', 'o-200']
  spec.summary       = 'Yet Another Neocities.org CLI and API client with improvements'
  spec.homepage      = 'https://github.com/o-200/neocities-red'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(tests)/})
  spec.require_paths = ['lib']
  spec.extensions    = ['ext/mkrf_conf.rb']
  spec.required_ruby_version = '>= 3.4.0'

  spec.add_dependency 'faraday', '~> 2.3', '>= 2.14.0'
  spec.add_dependency 'faraday-follow_redirects'
  spec.add_dependency 'faraday-multipart'
  spec.add_dependency 'pastel', '~> 0.8', '= 0.8.0'
  spec.add_dependency 'rake', '~> 13', '>= 13.3.0'
  spec.add_dependency 'tty-prompt', '~> 0.23', '= 0.23.1'
  spec.add_dependency 'tty-table', '~> 0.12', '= 0.12.0'
  spec.add_dependency 'whirly', '~> 0.3', '>= 0.3.0'
end