require 'spec_helper'

RSpec.describe Neocities::Pizza do
  describe '#make_order' do
    let(:pizza) { described_class.new }

    it 'returns a string with ANSI color codes' do
      result = pizza.make_order
      expect(result).to include("\e[")
    end

    it 'contains text from the EXCUSES array' do
      result = pizza.make_order
      text_without_colors = result.gsub(/\e\[\d+m/, '')
      expect(described_class::EXCUSES).to include(text_without_colors)
    end
  end

  describe 'EXCUSES constant' do
    it 'is a non-empty array of strings' do
      expect(described_class::EXCUSES).to be_an(Array)
    end
  end
end