# frozen_string_literal: true

require "pastel"
require "tty/table"

module NeocitiesRed
  module Services
    module Site
      # Compares local files against the remote Neocities site.
      #
      # Identifies three categories of differences:
      # - **Added** — files present locally but not on the server
      # - **Modified** — files present in both but with different SHA1 hashes
      # - **Removed** — files present on the server but not locally
      #
      # Results are color-coded: green for added, yellow for modified,
      # red for removed.
      #
      # @example
      #   differencer = NeocitiesRed::Services::Site::Differencer.new(
      #     client, path: ".", detail: false, ignore_dotfiles: false, exclude: []
      #   )
      #   added, modified, removed = differencer.show
      #
      # @see NeocitiesRed::Services::File::List Fetches the remote file list
      class Differencer
        # @param client [NeocitiesRed::Client] authenticated API client
        # @param path [String] local directory path to compare (default: ".")
        # @param detail [Boolean] whether to show detailed output (default: false)
        # @param ignore_dotfiles [Boolean] when true, ignores files starting with "."
        # @param exclude [Array<String>] local paths to exclude from comparison
        def initialize(client, path: ".", detail: false, ignore_dotfiles: false, exclude: [])
          @client = client
          @path = path
          @detail = detail || false
          @ignore_dotfiles = ignore_dotfiles || false
          @exclude = exclude || []
          @pastel = Pastel.new(eachline: "\n")
        end

        # Computes the diff between local and remote files.
        #
        # @return [Array(Array<String>, Array<String>, Array<String>)]
        #   a tuple of +[added, modified, removed]+, where each element
        #   is an array of color-coded file path strings
        def show
          server_files = Services::File::List.new(@client, nil, @detail).show

          root_path = Pathname(@path)

          added_paths = []
          removed_paths = []
          modified_paths = []

          Dir.chdir(root_path) do
            paths = Dir.glob(::File.join("**", "*"), ::File::FNM_DOTMATCH)

            server_file_entries = server_files.reject { |file| file[:is_directory] }
            server_paths = server_file_entries.map { |file| file[:path] }
            server_file_map = server_file_entries.to_h do |file|
              [file[:path], file[:sha1_hash]]
            end

            local_paths = paths

            if @ignore_dotfiles
              server_paths = server_paths.reject { |path| path.start_with?(".") }
              local_paths = local_paths.reject { |path| path.start_with?(".") }
            end

            local_files = local_paths.select { |path| ::File.file?(path) }.map do |path|
              {
                path: path,
                sha1_hash: Digest::SHA1.file(path).hexdigest
              }
            end

            if @exclude.any?
              normalized_exclude = @exclude.map { |path| Pathname.new(path).cleanpath.to_s }
              server_paths -= normalized_exclude
              local_paths -= normalized_exclude
            end

            removed_paths = server_paths - local_paths
            removed_paths.map! { |file| @pastel.red(file) }

            added_paths = local_paths - server_paths
            added_paths.map! { |file| @pastel.green(file) }

            modified_paths = local_files.select do |file|
              server_hash = server_file_map[file[:path]]
              server_hash && server_hash != file[:sha1_hash]
            end
            modified_paths.map! { |file| @pastel.yellow(file[:path]) }
          end

          [
            added_paths,
            modified_paths,
            removed_paths
          ]
        end
      end
    end
  end
end
