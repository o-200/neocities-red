# frozen_string_literal: true

require "pastel"

module NeocitiesRed
  # Terminal output helper for the CLI.
  #
  # Wraps all user-facing output — progress indicators, success/error
  # messages, help screens, and the ASCII art banner. Uses Pastel for
  # colored and styled terminal output.
  #
  # Every +display_*+ method prints to stdout and may call +exit+
  # (for help screens). Non-help methods return +nil+.
  #
  # @example
  #   display = NeocitiesRed::CliDisplay.new
  #   display.display_response(result: "success", message: "Uploaded!")
  #
  # @see NeocitiesRed::CLI Uses this class for all terminal output
  class CliDisplay
    # @return [Array<String>] Mouth sprites for the Penelope banner cat.
    PENELOPE_MOUTHS = %w[^ o ~ - v U].freeze

    # @return [Array<String>] Eye sprites for the Penelope banner cat.
    PENELOPE_EYES = %w[o ~ O].freeze

    # Creates a new display instance.
    #
    # @param io [IO] output stream (defaults to +$stdout+; inject a
    #   StringIO for testing)
    def initialize(io: $stdout)
      @io = io
      @pastel = Pastel.new(eachline: "\n")
    end

    # Prints a message followed by a newline.
    #
    # @param message [String] text to print
    # @return [void]
    def say(message = "")
      @io.puts(message)
    end

    # Displays an API response with appropriate coloring.
    #
    # Handles three response shapes:
    # - +Exception+ — prints the error message in red and exits
    # - +:result == "success"+ — prints in green
    # - +:result == "error" && :error_type == "file_exists"+ — prints in yellow
    # - All other errors — prints in red
    #
    # @param resp [Hash, Exception] API response or exception
    # @return [void]
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

    # Displays the results of a diff operation.
    #
    # Prints removed files in red, modified files in yellow,
    # and added files in green. Each section is only shown if non-empty.
    #
    # @param added [Array<String>] local files not present on the server
    # @param modified [Array<String>] files whose SHA1 hash differs
    # @param removed [Array<String>] server files not present locally
    # @return [void]
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

    # Prints the interactive login prompt message.
    #
    # @return [void]
    def display_login_prompt
      say "Please login to get your API key:"
    end

    # Confirms that the API key has been saved to disk.
    #
    # @param sitename [String] the site name
    # @param path [String] the config file path where the key was stored
    # @return [void]
    def display_api_key_saved(sitename, path)
      say "The api key for #{@pastel.bold(sitename)} has been stored in #{@pastel.bold(path)}."
    end

    # Displays an unknown CLI option error.
    #
    # @param option [String] the unrecognized option
    # @return [void]
    def display_unknown_option(option)
      say @pastel.red.bold("Unknown option: #{option.inspect}")
    end

    # Displays a logout success message.
    #
    # @return [void]
    def display_logout_success
      say @pastel.bold("Your api key has been removed.")
    end

    # Displays a notice that the current operation is a dry run.
    #
    # @return [void]
    def display_dry_run_notice
      say @pastel.green.bold("Doing a dry run, not actually pushing anything")
    end

    # Prints the file deletion progress indicator (without newline).
    #
    # @param path [String] remote file path being deleted
    # @return [void]
    def display_delete_progress(path)
      @io.print @pastel.bold("Deleting #{path} ... ")
    end

    # Prints a green "SUCCESS" after a file is deleted.
    #
    # @return [void]
    def display_delete_success
      @io.print "#{@pastel.green.bold('SUCCESS')}\n"
    end

    # Prints an error response that occurred during file deletion.
    #
    # @param resp [Hash] the API error response
    # @return [void]
    def display_delete_error(resp)
      @io.print "\n"
      display_response(resp)
    end

    # Displays a hint that .gitignore entries are being excluded.
    #
    # @return [void]
    def display_gitignore_hint
      say "Not pushing .gitignore entries (--no-gitignore to disable)"
    end

    # Prints the file upload progress indicator (without newline).
    #
    # @param path [String] local file path being uploaded
    # @param remote_path [String] remote destination path
    # @return [void]
    def display_upload_progress(path, remote_path)
      @io.print @pastel.bold("Uploading #{path} to #{remote_path} ... ")
    end

    # Prints a green "SUCCESS" after a file is uploaded.
    #
    # @return [void]
    def display_upload_success
      @io.print "#{@pastel.green.bold('SUCCESS')}\n"
    end

    # Prints a yellow "EXISTS" when the uploaded file already matches remotely.
    #
    # @return [void]
    def display_upload_exists
      @io.print "#{@pastel.yellow.bold('EXISTS')}\n"
    end

    # Displays a message that a directory path is being skipped.
    #
    # @param path [String] the directory path that was skipped
    # @return [void]
    def display_skip_directory(path)
      say @pastel.bold("#{path} is a directory, skipping")
    end

    # Displays a message that a non-directory path is being skipped
    # (during folder upload).
    #
    # @param path [String] the file path that was skipped
    # @return [void]
    def display_skip_file(path)
      say @pastel.bold("#{path} is not a directory, skipping")
    end

    # Displays a message that all file uploads are complete.
    #
    # @return [void]
    def display_upload_complete
      say "All files uploaded."
    end

    # Renders a TTY::Table to the output stream.
    #
    # @param table [TTY::Table] the table to display
    # @return [void]
    def display_list_table(table)
      say table
    end

    # Prints the file pull progress indicator (without newline).
    #
    # @param path [String] remote file path being pulled
    # @return [void]
    def display_pull_progress(path)
      @io.print @pastel.bold("Pulling #{path} ... ")
    end

    # Prints "NO NEW UPDATES" in yellow for files skipped during pull.
    #
    # @return [void]
    def display_pull_no_updates
      @io.print "#{@pastel.yellow.bold('NO NEW UPDATES')}\n"
    end

    # Prints a green "SUCCESS" after a file is pulled.
    #
    # @return [void]
    def display_pull_success
      @io.print "#{@pastel.green.bold('SUCCESS')}\n"
    end

    # Prints a red "FAIL" when a file pull fails.
    #
    # @return [void]
    def display_pull_failure
      @io.print "#{@pastel.red.bold('FAIL')}\n"
    end

    # Displays a summary of pull statistics.
    #
    # @param success_loaded [Integer] number of files successfully downloaded
    # @param total_time [Float] total elapsed time in seconds
    # @return [void]
    def display_pull_stats(success_loaded, total_time)
      say @pastel.green "\nSuccessfully fetched #{success_loaded} files in #{total_time.round(2)} seconds"
    end

    # Displays the pizza easter egg help screen and exits.
    #
    # @return [void]
    def display_pizza_help_and_exit
      say Services::Common::Pizza.new.make_order
      exit
    end

    # Displays the help screen for the +list+ command and exits.
    #
    # @return [void]
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

    # Displays the help screen for the +delete+ command and exits.
    #
    # @return [void]
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

    # Displays the help screen for the +upload+ command and exits.
    #
    # @return [void]
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

    # Displays the help screen for the +pull+ command and exits.
    #
    # @return [void]
    def display_pull_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.magenta.bold 'pull'} - Get the most recent version of files from your site, does not download if files haven't changed
      HERE
      exit
    end

    # Displays the help screen for the +push+ command and exits.
    #
    # @return [void]
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

    # Displays the help screen for the +diff+ command and exits.
    #
    # @return [void]
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

    # Displays the help screen for the +info+ command and exits.
    #
    # @return [void]
    def display_info_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'info'} - Get site info

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red info fauux'}   Gets info for 'fauux' site
      HERE
      exit
    end

    # Displays the help screen for the +logout+ command and exits.
    #
    # @return [void]
    def display_logout_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'logout'} - Remove the site api key from the config

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red logout -y'}
      HERE
      exit
    end

    # Displays the help screen for the +purge+ command and exits.
    #
    # @return [void]
    def display_purge_help_and_exit
      display_banner

      say <<~HERE
        #{@pastel.green.bold 'purge'} - Remove all files from your site

        #{@pastel.dim 'Examples:'}

        #{@pastel.green '$ neocities-red purge -y'}                Delete all files from your site

        #{@pastel.green '$ neocities-red purge -y --dry-run'}      Show what would be deleted
      HERE
      exit
    end

    # Renders the ASCII art banner with a random Penelope cat face.
    #
    # @return [void]
    def display_banner
      say <<~HERE

        |\\---/|
        | #{PENELOPE_EYES.sample}_#{PENELOPE_EYES.sample} |  #{@pastel.on_red.bold ' Neocities red '}
         \\_#{PENELOPE_MOUTHS.sample}_/

      HERE
    end

    # Displays the main help screen listing all available subcommands and exits.
    #
    # @return [void]
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
