# frozen_string_literal: true

module DSLHelper
  def class_dsl(parent = Schema::Definition, &block)
    Class.new(parent, &block)
  end

  def plugin_dsl(&block)
    Class.new(Schema::Plugin, &block)
  end
end
