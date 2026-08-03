# frozen_string_literal: true

require "pastel"
require "tty/table"

module NeocitiesRed
  module Services
    module Site
      class Differencer
        def initialize(client, path: ".", detail: false, ignore_dotfiles: false, exclude: [])
          @client = client
          @path = path
          @detail = detail || false
          @ignore_dotfiles = ignore_dotfiles || false
          @exclude = exclude || []
          @pastel = Pastel.new(eachline: "\n")
        end

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
