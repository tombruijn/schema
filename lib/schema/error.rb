# frozen_string_literal: true

module Schema
  class Error < StandardError
    class FrozenError < Error; end

    class CheckFailedError < Error
      def initialize(attribute)
        super(nil)
        @attribute = attribute
      end

      def message
        path = @attribute.root? ? :__root__ : @attribute.full_path
        "Attribute check failed for '#{path}'"
      end
    end
  end
end
