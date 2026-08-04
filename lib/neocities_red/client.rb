# frozen_string_literal: true

if Gem.win_platform?
  begin
    require "openssl/win/root"
  rescue LoadError
    # Optional dependency that helps Windows trust store integration.
  end
end
require "json"
require "pathname"
require "uri"
require "digest"
require "date"

require "faraday"
require "faraday/retry"
require "faraday/multipart"
require "faraday/follow_redirects"

module NeocitiesRed
  # HTTP client for the Neocities API.
  #
  # Wraps all API interactions — listing, uploading, deleting, and querying
  # site information. Supports both API-key (Bearer) and basic-auth
  # (sitename/password) authentication.
  #
  # Retries transient failures (429, 5xx) automatically via Faraday::Retry.
  #
  # @example API key authentication
  #   client = NeocitiesRed::Client.new(api_key: "your-api-key")
  #   client.list
  #
  # @example Basic auth authentication
  #   client = NeocitiesRed::Client.new(sitename: "my-site", password: "secret")
  #   client.list
  class Client
    # @return [String] Base URL for the Neocities REST API.
    API_URI = "https://neocities.org/api/"

    # Creates a new API client.
    #
    # @param opts [Hash] authentication options
    # @option opts [String] :api_key Bearer token for API-key authentication
    # @option opts [String] :sitename site name for basic-auth (requires +:password+)
    # @option opts [String] :password site password for basic-auth (requires +:sitename+)
    # @raise [ArgumentError] if neither +:api_key+ nor (+:sitename+ and +:password+) are provided
    def initialize(opts = {})
      @uri = URI.parse API_URI
      @opts = opts
      @conn = Faraday.new(@uri) do |conn|
        conn.options.timeout = 30
        conn.options.open_timeout = 10
        conn.adapter :net_http

        conn.request :multipart
        conn.request :url_encoded

        conn.request :retry,
                     max: 3,
                     interval: 0.3,
                     backoff_factor: 2,
                     retry_statuses: [429, 500, 502, 503, 504],
                     exceptions: [
                       Faraday::TimeoutError,
                       Faraday::ConnectionFailed,
                       Faraday::SSLError
                     ]

        conn.response :follow_redirects
      end

      raise ArgumentError, "client requires a login (sitename/password) or an api_key" unless opts[:api_key] || (opts[:sitename] && opts[:password])

      if opts[:api_key]
        @conn.request(:authorization, "Bearer", opts[:api_key])
      else
        @conn.request(:authorization, :basic, opts[:sitename], opts[:password])
      end
    end

    # Lists files on the remote Neocities site.
    #
    # @param path [String, nil] directory path to list (nil for root)
    # @return [Hash] parsed API response containing +:files+ array
    def list(path = nil)
      get "list", path: path
    end

    # Retrieves the API key for the currently authenticated user.
    #
    # Only meaningful when authenticated via basic-auth (sitename/password).
    #
    # @return [Hash] parsed API response containing +:api_key+
    def key
      get "key"
    end

    # Checks whether the remote file matches the given SHA1 hash.
    #
    # Used by {#upload} to skip uploading files that haven't changed.
    #
    # @param remote_path [String] remote file path to check
    # @param sha1_hash [String] hex-encoded SHA1 hash of the local file
    # @return [Hash] parsed API response with +:files+ mapping paths to booleans
    def upload_hash(remote_path, sha1_hash)
      post "upload_hash", remote_path => sha1_hash
    end

    # Uploads a single file to the Neocities site.
    #
    # Computes the SHA1 hash of the local file and compares it with the
    # remote version. If the file already exists remotely with the same
    # hash, the upload is skipped and an "exists" response is returned.
    #
    # @param path [String, Pathname] local file path to upload
    # @param remote_path [String, nil] remote destination path; defaults to the basename of +path+
    # @param dry_run [Boolean] when true, simulates the upload without sending data
    # @return [Hash] API response with +:result+ key ("success", "error", or "file_exists")
    # @raise [ArgumentError] if the local file does not exist
    def upload(path, remote_path = nil, dry_run: false)
      path = Pathname path
      raise ArgumentError, "#{path} does not exist." unless path.exist?

      rpath = remote_path || path.basename
      res = upload_hash(rpath.to_s, Digest::SHA1.file(path.to_s).hexdigest)

      file_exists_remotely = if res[:files]
                               res[:files][rpath.to_s.to_sym] == true || res[:files][rpath.to_s] == true
                             else
                               false
                             end

      if file_exists_remotely
        {
          result: "error",
          error_type: "file_exists",
          message: "file already exists and matches local file, not uploading"
        }
      else
        return { result: "success" } if dry_run

        File.open(path.to_s) do |file|
          post "upload", rpath.to_s => Faraday::Multipart::FilePart.new(file, "text/html")
        end
      end
    end

    # Deletes one or more remote files, with optional dry-run support.
    #
    # @param paths [Array<String>] remote file paths to delete
    # @param dry_run [Boolean] when true, simulates the deletion
    # @return [Hash] API response with +:result+ key
    def delete_wrapper_with_dry_run(paths, dry_run: false)
      return { result: "success" } if dry_run

      delete(paths)
    end

    # Deletes one or more files from the remote Neocities site.
    #
    # @param paths [Array<String>] remote file paths to delete
    # @return [Hash] parsed API response
    def delete(*paths)
      post "delete", "filenames" => paths
    end

    # Retrieves information and statistics for a Neocities site.
    #
    # @param sitename [String] the site name to query
    # @return [Hash] parsed API response containing +:info+ hash with
    #   site metadata (domain, created_at, last_updated, bandwidth, etc.)
    # @raise [NeocitiesRed::APIError] if the API returns an error
    def info(sitename)
      get "info", sitename: sitename
    end

    # Performs an HTTP GET request to the Neocities API.
    #
    # @param path [String] API endpoint path (e.g. "list", "info")
    # @param params [Hash] query parameters
    # @return [Hash] parsed JSON response with symbolized keys
    def get(path, params = {})
      uri = @uri + path
      uri.query = URI.encode_www_form params
      resp = @conn.get(uri)

      JSON.parse resp.body, symbolize_names: true
    end

    # Downloads a file from a URL.
    #
    # @param url [String] full URL to download
    # @return [Faraday::Response] raw Faraday response object
    def download(url)
      @conn.get(url)
    end

    # Performs an HTTP POST request to the Neocities API.
    #
    # @param path [String] API endpoint path (e.g. "upload", "delete")
    # @param args [Hash] request body parameters
    # @return [Hash] parsed JSON response with symbolized keys
    def post(path, args = {})
      uri = @uri + path
      resp = @conn.post(uri, args)

      JSON.parse resp.body, symbolize_names: true
    end
  end
end
