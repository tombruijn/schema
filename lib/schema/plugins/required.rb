# frozen_string_literal: true

module Schema
  module Plugins
    class RequiredPlugin < Schema::Plugin
      option :required,
        :default_value => true
      option :required_message,
        :default_value => "Required value for '%<full_path>s' is not set."

      check do |attr, required:, required_message:|
        next unless required
        next if attr.attr?
        next unless attr.value.nil?

        attr.add_error(
          format(required_message, :full_path => attr.full_path)
        )
      end
    end
  end
end
