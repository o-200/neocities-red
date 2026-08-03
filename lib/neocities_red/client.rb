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
  class Client
    API_URI = "https://neocities.org/api/"

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

    def list(path = nil)
      get "list", path: path
    end

    def key
      get "key"
    end

    def upload_hash(remote_path, sha1_hash)
      post "upload_hash", remote_path => sha1_hash
    end

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

    def delete_wrapper_with_dry_run(paths, dry_run: false)
      return { result: "success" } if dry_run

      delete(paths)
    end

    def delete(*paths)
      post "delete", "filenames" => paths
    end

    def info(sitename)
      get "info", sitename: sitename
    end

    def get(path, params = {})
      uri = @uri + path
      uri.query = URI.encode_www_form params
      resp = @conn.get(uri)

      JSON.parse resp.body, symbolize_names: true
    end

    def download(url)
      @conn.get(url)
    end

    def post(path, args = {})
      uri = @uri + path
      resp = @conn.post(uri, args)

      JSON.parse resp.body, symbolize_names: true
    end
  end
end
