require 'vcr'
require 'webmock/rspec'
require 'neocities'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter sensitive data (API keys)
  config.filter_sensitive_data('<API_KEY>') { ENV['NEOCITIES_API_KEY'] || 'test_api_key' }
  config.filter_sensitive_data('<SITENAME>') { ENV['NEOCITIES_SITENAME'] || 'test_site' }
  config.filter_sensitive_data('<PASSWORD>') { ENV['NEOCITIES_PASSWORD'] || 'test_password' }
  
  # Default cassette options
  config.default_cassette_options = {
    record: :once,  # :new_episodes, :none, :all, :once
    match_requests_on: [:method, :uri, :body]
  }
  
  # Filter headers
  config.before_record do |interaction|
    interaction.request.headers.delete('Authorization')
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"
  
  # Disable monkey patching
  config.disable_monkey_patching!
  
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
    expectations.syntax = :expect
  end
  
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  
  # Share VCR context
  config.shared_context_metadata_behavior = :apply_to_host_groups
  
  # Use VCR for all tests with :vcr metadata
  config.around(:each, :vcr) do |example|
    cassette_name = example.metadata[:cassette] || 
                   example.full_description
                     .gsub(/\s+/, '_')
                     .gsub(/[^\w\/]+/, '')
                     .downcase
                     .gsub(/_+$/, '')
    
    VCR.use_cassette(cassette_name, record: :once) do
      example.run
    end
  end
end

def test_api_key
  ENV['NEOCITIES_API_KEY'] || ''
end

def test_sitename
  ENV['NEOCITIES_SITENAME'] || 'areast'
end