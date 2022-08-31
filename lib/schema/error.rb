# frozen_string_literal: true

module Schema
  class Error < StandardError
    class FrozenError < Error; end

    class CheckFailedError < Error
      def initialize(field)
        super(nil)
        @field = field
      end

      def message
        "Field check failed for '#{@field.path}'"
      end
    end
  end
end
