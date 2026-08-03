# frozen_string_literal: true

require "pathname"

module NeocitiesRed
  module Services
    module Common
      module Exclusions
        module_function

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

        def normalize(path, base)
          return path unless base

          Pathname.new(path).expand_path.relative_path_from(base).to_s
        end
        private_class_method :normalize
      end
    end
  end
end
