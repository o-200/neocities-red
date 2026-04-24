# frozen_string_literal: true

require "pathname"
require "digest"

module NeocitiesRed
  module Services
    module Site
      class Pusher
        # warning - the big quantity of working threads could be considered like-a DDOS.
        # Your ip-address could get banned on neocities for a few days.
        MAX_THREADS = 5

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

        def push
          root_path = Pathname(@root)
          validate_root_path!(root_path)

          @display.display_dry_run_notice if @dry_run
          prune_remote_files if @prune

          excluded_files = build_push_exclusions(@exclude)

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

        def validate_root_path!(root_path)
          raise ArgumentError, "path #{root_path} does not exist" unless root_path.exist?
          raise ArgumentError, "provided path is not a directory" unless root_path.directory?
        end

        def build_push_exclusions(excluded_entries)
          excluded_files = []

          excluded_entries.each do |entry|
            filepath = Pathname.new(entry).cleanpath.to_s

            if ::File.file?(filepath)
              excluded_files << filepath
            elsif ::File.directory?(filepath)
              excluded_files.concat(Dir.glob(::File.join(filepath, "**", "*"), ::File::FNM_DOTMATCH).push(filepath))
            end
          end

          excluded_files
        end

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

        def optimized_exclusions(paths)
          hex = paths.select { |path| ::File.file?(path) }
                     .map { |file| { filepath: file, sha1_hash: Digest::SHA1.file(file).hexdigest } }

          res = @client.list
          server_hex = res[:files].map { |item| item[:sha1_hash] }.compact

          hex.select { |entry| server_hex.include?(entry[:sha1_hash]) }.map { |entry| entry[:filepath] }
        end

        def upload_files(paths)
          task_queue = Queue.new
          paths.each { |path| task_queue.push(path) }

          threads = []
          MAX_THREADS.times do
            threads << Thread.new do
              until task_queue.empty?
                path = begin
                  task_queue.pop(true)
                rescue StandardError
                  nil
                end

                next if path.nil? || path.directory?

                Services::File::Uploader.new(@client, path, path).upload
              end
            end
          end

          threads.each(&:join)
          @display.display_upload_complete
        end

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
