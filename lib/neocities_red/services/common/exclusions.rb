# frozen_string_literal: true

require "pathname"

module NeocitiesRed
  module Services
    module Common
      # Builds normalized exclusion lists from user-provided paths.
      #
      # Given a list of file or directory paths, expands them into all
      # contained files and normalizes them relative to a base path.
      # This is used by {NeocitiesRed::Services::Site::Pusher} to apply
      # the +--exclude+ option.
      #
      # @example
      #   excluded = Exclusions.build(["node_modules", "secret.txt"], base_path: ".")
      #   # => ["node_modules/...", "secret.txt"]
      #
      # @see NeocitiesRed::Services::Site::Pusher#push Uses exclusions during push
      module Exclusions
        module_function

        # Builds a normalized exclusion list from the given entries.
        #
        # For each entry:
        # - If it is a file, includes it directly
        # - If it is a directory, recursively includes all contained files
        # - Non-existent entries are silently skipped
        #
        # @param excluded_entries [Array<String>] file or directory paths to exclude
        # @param base_path [String, nil] base directory for path normalization;
        #   when provided, paths are made relative to this base
        # @return [Array<String>] flattened, deduplicated list of normalized paths
        def build(excluded_entries, base_path: nil)
          base = base_path && Pathname.new(base_path).expand_path

          excluded_entries.flat_map do |entry|
            target = base ? Pathname.new(entry).expand_path : Pathname.new(entry).cleanpath
            next [] unless target.exist?

            paths =
              if ::File.file?(target)
                [target.to_s]
              elsif ::File.directory?(target)
                Dir.glob(::File.join(target, "**", "*"), ::File::FNM_DOTMATCH)
              else
                []
              end

            paths.push(target.to_s) if ::File.directory?(target)
            paths.map { |path| normalize(path, base) }.uniq
          end
        end

        # Normalizes a path relative to a base directory.
        #
        # @param path [String] absolute or relative path
        # @param base [String, nil] base directory; when nil, returns the path as-is
        # @return [String] the path relative to +base+, or the original path
        def normalize(path, base)
          return path unless base

          Pathname.new(path).expand_path.relative_path_from(base).to_s
        end
        private_class_method :normalize
      end
    end
  end
end
