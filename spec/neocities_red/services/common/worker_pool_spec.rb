# frozen_string_literal: true

require "spec_helper"

RSpec.describe NeocitiesRed::Services::Common::WorkerPool do
  let(:result) { [] }
  let(:mutex) { Mutex.new }

  def pool_of(size)
    described_class.new(size) do |item|
      mutex.synchronize { result << item }
    end
  end

  describe "#process" do
    it "calls the block for each item" do
      pool_of(3).process([1, 2, 3, 4, 5])

      expect(result.sort).to eq([1, 2, 3, 4, 5])
    end

    it "processes items across multiple threads" do
      threads_seen = []
      pool = described_class.new(4) do |item|
        sleep 0.002
        threads_seen << Thread.current.object_id
        result << item
      end

      pool.process(Array.new(20, :work))

      expect(threads_seen.uniq.size).to be > 1
      expect(result.size).to eq(20)
    end

    it "works with a single worker" do
      pool_of(1).process(%w[a b c])

      expect(result).to eq(%w[a b c])
    end

    it "returns immediately for an empty list" do
      expect { pool_of(2).process([]) }.not_to raise_error

      expect(result).to be_empty
    end
  end
end
