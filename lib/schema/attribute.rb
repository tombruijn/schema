# frozen_string_literal: true

require "set"

module Schema
  class Attribute
    def self.inherited(base)
      super
      base.plugins = plugins.dup
      base.options = options.dup
      base.attributes = attributes.dup
    end

    class << self
      def plugins
        @plugins ||= Set.new
      end

      def plugin(*plugs)
        plugs.each do |plug|
          next unless plugins.add?(plug)

          extend plug.class_dsl
          include plug.instance_dsl

          # Import default config options from plugins
          plug.options.each do |option, config|
            default_value = config[:default_value]
            options[option] = default_value unless default_value.nil?
          end
        end
      end

      def attributes
        @attributes ||= {}
      end

      def attribute(name, klass = Schema::Attribute, **options, &block)
        # TODO: add checks for two attributes with the same name being defined
        unless klass <= Schema::Attribute
          # TODO: check if it's of the correct inheritance
          # TODO: test this
          raise "Not the correct parent class"
        end

        definition = Class.new(klass)
        definition.plugin(*plugins) if klass == Schema::Attribute
        definition.options.merge!(options)
        const_set("#{name.capitalize}Attribute", definition)
        definition.instance_eval(&block) if block_given?

        attributes[name.to_sym] = definition
      end

      def options
        @options ||= {}
      end

      def visible(value = nil)
        option :visible, value
      end

      def checks
        @checks ||= []
      end

      def check(func = nil, &block)
        checks << func if func.respond_to? :call
        checks << block if block_given?
      end

      protected

      attr_writer :plugins, :options, :attributes

      private

      def option(key, value = nil, &block)
        options[key] = value unless value.nil?
        options[key] = block if block_given?
        options[key]
      end
    end

    ROOT_PATH = nil

    attr_reader :path, :value, :attributes
    attr_writer :visible

    def initialize(values = {}, path = ROOT_PATH)
      @path = path if path != ROOT_PATH
      @attributes = {}
      @visible = true
      @value = values

      if self.class.attributes.any?
        names = (self.class.attributes.keys | values.keys).map(&:to_sym)
        names.each do |attr|
          value = values.fetch(attr, values.fetch(attr.to_s, {}))
          set_attribute([*path, attr], value)
        end
      end
    end

    def check!
      return if @checked

      @checked = true

      check_if_visible
      return unless visible?

      check_plugins
      return unless visible?

      check_attribute
    rescue StandardError
      raise Error::CheckFailedError, self
    end

    def name
      path&.last&.to_sym
    end

    def full_path
      path.join(".")
    end

    def visible?
      !!@visible
    end

    def [](key)
      attributes[key]
    end

    # TODO: remove?
    def []=(key, value)
      set_attribute(key, value)
    end

    def issues
      @issues ||= []
    end

    def valid?
      return true unless visible?

      self_valid = issues.select { |issue| issue.type == :error }.empty?
      return false unless self_valid

      attributes.each_value do |attr|
        return false unless attr.valid?
      end
      true
    end

    def errors?
      return false unless visible?

      issues.any? { |issue| issue.type == :error }
    end

    def warnings?
      return false unless visible?

      issues.any? { |issue| issue.type == :warning }
    end

    def notes?
      return false unless visible?

      issues.any? { |issue| issue.type == :note }
    end

    def issues?
      return false unless visible?

      issues.any?
    end

    def add_error(message)
      issues << Issue.new(:error, name, message)
    end

    def add_warning(message)
      issues << Issue.new(:warning, name, message)
    end

    def add_note(message)
      issues << Issue.new(:note, name, message)
    end

    def unknown?
      instance_of?(UnknownAttribute)
    end

    def deconstruct_keys(keys)
      deconstructed = {}
      if keys
        keys.each do |key|
          deconstructed[key] = self[key]
        end
      else
        attributes.each do |key, attr|
          deconstructed[key] = attr
        end
      end
      deconstructed
    end

    protected

    attr_writer :value

    private

    def set_attribute(name, value)
      attr_name = Array(name).last
      definition = self.class.attributes.fetch(attr_name, UnknownAttribute)
      if attributes.key?(attr_name)
        attributes[attr_name].value = value
      else
        attributes[attr_name] = definition.new(value, name)
      end
    end

    def check_if_visible
      visible_option = self.class.options[:visible]
      if [true, false].include?(visible_option)
        self.visible = visible_option
        return
      end

      return unless visible_option.respond_to?(:call)

      self.visible = visible_option.call(self, **context)
    end

    def check_plugins
      attribute_options = self.class.options.keys
      self.class.plugins.each do |plugin|
        plugin_options = plugin.options.keys
        if plugin_options.any? && (plugin_options & attribute_options).empty?
          # Skip if the plugin has any options, but none are on this attribute
          next
        end

        plugin.checks.each do |check|
          # Skip next plugins if one plugin made the attribute invisible
          break unless visible?

          options = {}
          if check.arity > 1
            _, *params = check.parameters
            params.map do |(type, param)|
              options[param] = self.class.options[param] if type == :keyreq
            end
          end
          if options.any?
            check.call(self, **options)
          else
            check.call(self)
          end
        end
      end
    end

    def check_attribute
      self.class.checks.each do |check|
        check.call(self)
      end

      attributes.each_value(&:check!)
    end
  end

  Definition = Attribute
end
