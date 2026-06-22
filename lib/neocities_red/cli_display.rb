# frozen_string_literal: true

require "pastel"

module NeocitiesRed
  class CliDisplay
    PENELOPE_MOUTHS = %w[^ o ~ - v U].freeze
    PENELOPE_EYES = %w[o ~ O].freeze

    def initialize(io: $stdout)
      @io = io
      @pastel = Pastel.new(eachline: "\n")
    end

    def say(message = "")
      @io.puts(message)
    end

    def display_response(resp)
      if resp.is_a?(Exception)
        say "#{@pastel.red.bold('ERROR:')} #{resp.detailed_message}"
        exit
      end

      if resp[:result] == "success"
        say "#{@pastel.green.bold('SUCCESS:')} #{resp[:message]}"
      elsif resp[:result] == "error" && resp[:error_type] == "file_exists"
        out = "#{@pastel.yellow.bold('EXISTS:')} #{resp[:message]}"
        out += " (#{resp[:error_type]})" if resp[:error_type]
        say out
      else
        out = "#{@pastel.red.bold('ERROR:')} #{resp[:message]}"
        out += " (#{resp[:error_type]})" if resp[:error_type]
        say out
      end
    end

    def display_diff_results(added:, modified:, removed:)
      if removed.any?
        say @pastel.bold.red("Removed files")
        say removed
      end

      if modified.any?
        say @pastel.bold.yellow("Modified files")
        say modified
      end

      return unless added.any?

      say @pastel.bold.green("New files")
      say added
    end

    def display_login_prompt
      say "Please login to get your API key:"
    end

    def display_api_key_saved(sitename, path)
      say "The api key for #{@pastel.bold(sitename)} has been stored in #{@pastel.bold(path)}."
    end

    def display_unknown_option(option)
      say @pastel.red.bold("Unknown option: #{option.inspect}")
    end

    def display_logout_success
      say @pastel.bold("Your api key has been removed.")
    end

    def display_dry_run_notice
      say @pastel.green.bold("Doing a dry run, not actually pushing anything")
    end

    def display_delete_progress(path)
      @io.print @pastel.bold("Deleting #{path} ... ")
    end

    def display_delete_success
      @io.print "#{@pastel.green.bold('SUCCESS')}\n"
    end

    def display_delete_error(resp)
      @io.print "\n"
      display_response(resp)
    end

    def display_gitignore_hint
      say "Not pushing .gitignore entries (--no-gitignore to disable)"
    end

    def display_upload_complete
      say "All files uploaded."
    end

    def display_pizza_help_and_exit
      say Services::Common::Pizza.new.make_order
      exit
    end

    def display_list_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'list'} - List files on your Neocities site

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red list .'}           List files in your root directory

        #{@pastel.green '$ neocities-red list -a'}          Recursively display all files and directories

        #{@pastel.green '$ neocities-red list -d /mydir'}   Show detailed information on /mydir
      HERE
      exit
    end

    def display_delete_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'delete'} - Delete files on your Neocities site

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red delete myfile.jpg'}               Delete myfile.jpg

        #{@pastel.green '$ neocities-red delete myfile.jpg myfile2.jpg'}   Delete myfile.jpg and myfile2.jpg

        #{@pastel.green '$ neocities-red delete mydir'}                    Deletes mydir and everything inside it (be careful!)
      HERE
      exit
    end

    def display_upload_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'upload'} - Upload a file/folder to a path on your Neocities site

        #{@pastel.dim 'Usage:'}

            neocities-red upload LOCAL_PATH [REMOTE_PATH]

        REMOTE_PATH defaults to the basename of LOCAL_PATH when omitted.

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red upload foo.html'}             Uploads foo.html as /foo.html

        #{@pastel.green '$ neocities-red upload images/'}              Uploads images/ contents to /images/

        #{@pastel.green '$ neocities-red upload images/ assets/'}      Uploads images/ contents to /assets/

        #{@pastel.green '$ neocities-red upload ./img.jpg /images/'}   Uploads img.jpg to /images/img.jpg
      HERE
      exit
    end

    def display_pull_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.magenta.bold 'pull'} - Get the most recent version of files from your site, does not download if files haven't changed
      HERE
      exit
    end

    def display_push_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'push'} - Recursively upload a local directory to your Neocities site

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red push .'}                                 Recursively upload current directory.

        #{@pastel.green '$ neocities-red push . -e node_modules -e secret.txt'}   Exclude certain files from push

        #{@pastel.green '$ neocities-red push . --no-gitignore'}                  Don't use .gitignore to exclude files

        #{@pastel.green '$ neocities-red push . --ignore-dotfiles'}               Ignore files with '.' at the beginning (for example, '.git/')

        #{@pastel.green '$ neocities-red push . --dry-run'}                       Just show what would be uploaded

        #{@pastel.green '$ neocities-red push . --optimized'}                     Do not upload unchanged files.

        #{@pastel.green '$ neocities-red push . --prune'}                         Delete site files not in dir (be careful!)
      HERE
      exit
    end

    def display_diff_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'diff'} - Compare local files with remote and show differences.

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red diff .'}                             Compare your current path with remote

        #{@pastel.green '$ neocities-red diff ./my-website'}                  Compare ./my-website folder with remote

        #{@pastel.green '$ neocities-red diff . --ignore-dotfiles'}           Compare your current path with remote without files starting with '.'

        #{@pastel.green '$ neocities-red diff . -e file.png'}                 Compare your current path with remote without file.png
      HERE
      exit
    end

    def display_info_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'info'} - Get site info

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red info fauux'}   Gets info for 'fauux' site
      HERE
      exit
    end

    def display_logout_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'logout'} - Remove the site api key from the config

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red logout -y'}
      HERE
      exit
    end

    def display_purge_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'purge'} - Remove all files from your site

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red purge -y'}
      HERE
      exit
    end

    def display_banner
      say <<~HERE

        |\\---/|
        | #{PENELOPE_EYES.sample}_#{PENELOPE_EYES.sample} |  #{@pastel.on_red.bold ' Neocities red '}
         \\_#{PENELOPE_MOUTHS.sample}_/

      HERE
    end

    def display_help_and_exit
      display_banner
      say <<~HERE
        #{@pastel.dim 'Subcommands:'}
          delete      Delete files from your Neocities site
          diff        Compare your local directory with your Neocities site
          info        Information and stats for your site
          list        List files from your Neocities site
          logout      Remove the site api key from the config
          pizza       Order a free pizza
          pull        Get the most recent version of files from your site
          purge       Remove all files from your site
          push        Recursively upload a local directory to your site
          upload      Upload individual files to your Neocities site
          version     Unceremoniously display version and self destruct
      HERE
      exit
    end
  end
end
