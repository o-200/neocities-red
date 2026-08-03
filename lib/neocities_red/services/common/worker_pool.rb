# frozen_string_literal: true

module NeocitiesRed
  module Services
    module Common
      class WorkerPool
        def initialize(size, &block)
          @size = size
          @block = block
        end

        def process(items)
          queue = Queue.new
          items.each { |item| queue << item }

          workers = Array.new(@size) do
            Thread.new do
              loop do
                item = queue.pop(true)
                @block.call(item)
              rescue ThreadError
                break
              end
            end
          end

          workers.each(&:join)
        end
      end
    end
  end
end
