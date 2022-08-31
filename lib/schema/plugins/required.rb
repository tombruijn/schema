# frozen_string_literal: true

module Schema
  module Plugins
    class RequiredPlugin < Schema::Plugin
      option :required,
        :default_value => true
      option :required_message,
        :default_value => "Required value for '%<full_path>s' is not set."

      check do |attribute, required:, required_message:|
        next unless required
        next if attribute.attributes?
        next unless attribute.value.nil?

        field.add_error(
          format(required_message, :full_path => attribute.full_path)
        )
      end
    end
  end
end
