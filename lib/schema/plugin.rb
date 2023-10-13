# frozen_string_literal: true

module Schema
  class Plugin
    def self.options
      @options ||= {}
    end

    def self.option(name, config = {})
      options[name] = config
    end

    def self.checks
      @checks ||= []
    end

    def self.check(&block)
      checks << block
    end

    def self.class_dsl
      return self::ClassDSL if defined? self::ClassDSL

      mod = Module.new
      options.each_key do |option|
        mod.define_method option do |value|
          # TODO: check if works. Add &block to block arguments
          # option(option, value, &block)
          options[option] = value
        end
      end
      const_set(:ClassDSL, mod)
      mod
    end

    def self.instance_dsl
      return self::InstanceDSL if defined? self::InstanceDSL

      mod = Module.new
      options.each_key do |option|
        mod.define_singleton_method option do |value|
          options[option] = value
        end

        mod.define_method option do
          self.class.options[option]
        end
      end
      const_set(:InstanceDSL, mod)
      mod
    end

    def self.helpers(&block)
      return @helpers if defined?(@helpers)

      @helpers = Module.new(&block)
      const_set(:HelpersDSL, @helpers)
      @helpers
    end

    def self.helpers_dsl
      @helpers
    end

    class << self
      alias helpers? helpers_dsl
    end
  end
end
