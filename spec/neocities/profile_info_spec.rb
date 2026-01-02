require 'spec_helper'

RSpec.describe Neocities::ProfileInfo do
  let(:api_key) { test_api_key }
  let(:client) { Neocities::Client.new(api_key: api_key) }
  let(:sitename) { test_sitename }
  let(:subargs) { [] }

  let(:success) {
    {
      result: "success",
      info: {
        sitename: "areast",
        views: 27,
        hits: 121,
        created_at: "Sat, 27 Dec 2025 09:32:05 -0000",
        last_updated: "Tue, 30 Dec 2025 12:47:17 -0000",
        domain: nil,
        tags: ["are"]
      }
    }
  }
  
  subject(:profile_info) do
    described_class.new(client, subargs, sitename)
  end
  
  describe '#get_stats', :vcr do
    context 'with valid site' do
      it 'returns site statistics' do
        stats = profile_info.get_stats
        expect(stats).to eq(success)  
      end
    end
    
    context 'with invalid site' do
      let(:subargs) { ['nonexistent_site_12345'] }
      
      it 'raises ClientError', :vcr do
        expect { profile_info.get_stats }.to raise_error(Neocities::ClientError)
      end
    end
    
    context 'with specific sitename in subargs' do
      let(:subargs) { [sitename] }
      let(:sitename) { nil }
      
      it 'uses subargs sitename', :vcr do
        stats = profile_info.get_stats
        expect(stats).to eq(success)
      end
    end
  end
  
  describe 'error handling' do
    let(:error_response) do
      {
        result: 'error',
        error_type: 'not_found',
        message: 'Site not found'
      }
    end
    
    before do
      allow(client).to receive(:info).and_return(error_response)
    end
    
    it 'raises ClientError with error response' do
      expect { profile_info.get_stats }.to raise_error(
        Neocities::ClientError, /#{Regexp.escape(error_response.to_s)}/
      )
    end
  end
end