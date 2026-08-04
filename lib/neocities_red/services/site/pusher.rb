# frozen_string_literal: true

require "pathname"
require "digest"

module NeocitiesRed
  module Services
    # Site-level operations: push, diff, info, and export.
    module Site
      # Recursively uploads a local directory to the Neocities site.
      #
      # Orchestrates the full push workflow:
      # 1. Validates the root path
      # 2. Optionally prunes remote files not present locally
      # 3. Collects all files via glob
      # 4. Applies .gitignore rules, dotfile filtering, exclusions, and
      #    optimized (hash-based) filtering
      # 5. Uploads remaining files in parallel via a worker pool
      #
      # @example Basic push
      #   pusher = NeocitiesRed::Services::Site::Pusher.new(
      #     client, display,
      #     root: ".", no_gitignore: false, ignore_dotfiles: false,
      #     exclude: [], dry_run: false, prune: false, optimized: false
      #   )
      #   pusher.push
      #
      # @see NeocitiesRed::Services::File::Uploader Individual file upload
      # @see NeocitiesRed::Services::Common::Exclusions Exclusion builder
      # @see NeocitiesRed::Services::Common::WorkerPool Thread pool
      class Pusher
        # @return [Integer] maximum concurrent upload threads.
        #
        # Warning: a high thread count may be flagged as DDOS-like traffic
        # by Neocities, potentially resulting in a temporary IP ban.
        MAX_THREADS = 5

        # @param client [NeocitiesRed::Client] authenticated API client
        # @param display [NeocitiesRed::CliDisplay] output helper
        # @param root [String] local directory path to push
        # @param no_gitignore [Boolean] when true, ignores .gitignore rules
        # @param ignore_dotfiles [Boolean] when true, skips files starting with "."
        # @param exclude [Array<String>] additional paths to exclude from upload
        # @param dry_run [Boolean] when true, simulates the push without uploading
        # @param prune [Boolean] when true, deletes remote files not present locally
        # @param optimized [Boolean] when true, skips files whose SHA1 matches the server
        def initialize(client, display, root:, no_gitignore:, ignore_dotfiles:, exclude:, dry_run:, prune:, optimized:)
          @client = client
          @display = display
          @root = root
          @no_gitignore = no_gitignore
          @ignore_dotfiles = ignore_dotfiles
          @exclude = exclude
          @dry_run = dry_run
          @prune = prune
          @optimized = optimized
        end

        # Executes the full push workflow.
        #
        # @return [void]
        # @raise [ArgumentError] if the root path does not exist or is not a directory
        def push
          root_path = Pathname(@root)
          validate_root_path!(root_path)

          @display.display_dry_run_notice if @dry_run
          prune_remote_files if @prune

          excluded_files = Services::Common::Exclusions.build(@exclude)

          Dir.chdir(root_path) do
            paths = Dir.glob(::File.join("**", "*"), ::File::FNM_DOTMATCH)

            paths = apply_gitignore(paths) unless @no_gitignore
            excluded_files += paths.select { |path| path.start_with?(".") } if @ignore_dotfiles
            excluded_files += optimized_exclusions(paths) if @optimized

            filtered_paths = paths.difference(excluded_files).map { |path| Pathname(path) }
            upload_files(filtered_paths)
          end
        end

        private

        # Validates that the root path exists and is a directory.
        #
        # @param root_path [Pathname] the local root directory
        # @raise [ArgumentError] if validation fails
        def validate_root_path!(root_path)
          raise ArgumentError, "path #{root_path} does not exist" unless root_path.exist?
          raise ArgumentError, "provided path is not a directory" unless root_path.directory?
        end

        # Filters file paths based on .gitignore rules.
        #
        # Reads the local .gitignore and removes matching paths using
        # +File.fnmatch+ for glob pattern support.
        #
        # @param paths [Array<String>] all file paths in the root
        # @return [Array<String>> filtered paths not matched by .gitignore
        def apply_gitignore(paths)
          return paths unless ::File.exist?(".gitignore")

          ignores = ::File.readlines(".gitignore", chomp: true).map do |ignore|
            ::File.directory?(ignore) ? "#{ignore}**" : ignore
          end

          filtered = paths.select do |path|
            ignores.none? { |ignore| ::File.fnmatch?(ignore, path) }
          end

          @display.display_gitignore_hint
          filtered
        end

        # Computes which files can be skipped because their SHA1 hash
        # matches the server version.
        #
        # Fetches the remote file list, computes local SHA1 hashes, and
        # returns paths that don't need re-uploading.
        #
        # @param paths [Array<String>] all local file paths
        # @return [Array<String>] file paths to exclude (already up to date)
        def optimized_exclusions(paths)
          hex = paths.select { |path| ::File.file?(path) }
                     .map { |file| { filepath: file, sha1_hash: Digest::SHA1.file(file).hexdigest } }

          res = @client.list
          server_hash_by_path = res[:files].each_with_object({}) do |item, hash_by_path|
            next unless item[:path] && item[:sha1_hash]

            hash_by_path[item[:path]] = item[:sha1_hash]
          end

          hex.select { |entry| server_hash_by_path[entry[:filepath]] == entry[:sha1_hash] }
             .map { |entry| entry[:filepath] }
        end

        # Uploads all filtered paths in parallel using a worker pool.
        #
        # @param paths [Array<Pathname>] local files to upload
        # @return [void]
        def upload_files(paths)
          worker_pool = Services::Common::WorkerPool.new(MAX_THREADS) do |path|
            next if path.directory?

            Services::File::Uploader.new(@client, path, path, display: @display).upload
          end

          worker_pool.process(paths)
          @display.display_upload_complete
        end

        # Deletes remote files that no longer exist in the local directory.
        #
        # Skips directories that have already been pruned. Respects the
        # +@dry_run+ flag.
        #
        # @return [void]
        def prune_remote_files
          pruned_dirs = []
          resp = @client.list
          resp[:files].each do |file|
            path = Pathname(::File.join(@root, file[:path]))
            pruned_dirs << path if !path.exist? && file[:is_directory]

            next unless !path.exist? && !pruned_dirs.include?(path.dirname)

            @display.display_delete_progress(file[:path])
            delete_resp = @client.delete_wrapper_with_dry_run(file[:path], dry_run: @dry_run)
            if delete_resp[:result] == "success"
              @display.display_delete_success
            else
              @display.display_delete_error(delete_resp)
            end
          end
        end
      end
    end
  end
end
