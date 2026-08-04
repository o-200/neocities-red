# frozen_string_literal: true

module NeocitiesRed
  # Base error class for all NeocitiesRed exceptions.
  #
  # @abstract Subclass this for domain-specific errors.
  class Error < StandardError; end

  # Raised when the Neocities API returns a non-success response.
  #
  # Wraps error messages from the remote API so callers can inspect
  # the +:message+ and +:error_type+ fields from the response.
  class APIError < Error; end

  # Raised when a referenced file does not exist on the local filesystem.
  #
  # Typically raised by upload services when the source file
  # cannot be found at the given path.
  class FileNotFoundError < Error; end
end
