# frozen_string_literal: true

module Errors
  class InvalidLoginCode < StandardError
  end

  class ValidationError < StandardError
  end

  class BrowserMismatch < StandardError
  end

end
