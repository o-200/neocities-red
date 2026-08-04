# frozen_string_literal: true

module NeocitiesRed
  module Services
    module Common
      # A simple thread pool for parallel task execution.
      #
      # Processes a list of items concurrently using a fixed number of
      # worker threads. Each item is passed to the block provided at
      # construction time.
      #
      # @example
      #   pool = WorkerPool.new(5) { |item| puts item }
      #   pool.process([1, 2, 3, 4, 5])
      #
      # @see NeocitiesRed::Services::File::FolderUploader Uses for parallel uploads
      # @see NeocitiesRed::Services::Site::Pusher Uses for parallel uploads
      class WorkerPool
        # @param size [Integer] number of concurrent worker threads
        # @yield [item] block to execute for each item
        # @yieldparam item [Object] an item from the processing queue
        def initialize(size, &block)
          @size = size
          @block = block
        end

        # Processes all items in the pool using worker threads.
        #
        # Items are placed in a thread-safe queue and consumed by workers.
        # The method blocks until all items have been processed.
        #
        # @param items [Array<Object>] items to process
        # @return [void]
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
