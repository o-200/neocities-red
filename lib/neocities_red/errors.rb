# frozen_string_literal: true

module NeocitiesRed
  class Error < StandardError; end

  class AuthenticationError < Error; end

  class APIError < Error; end

  class FileNotFoundError < Error; end
end
