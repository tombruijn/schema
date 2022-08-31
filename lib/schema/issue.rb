# frozen_string_literal: true

module Schema
  class Issue
    attr_reader :type, :path, :message

    def initialize(type, path, message)
      @type = type
      @path = path
      @message = message
    end
  end
end
