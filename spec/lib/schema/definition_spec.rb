# frozen_string_literal: true

RSpec.describe Schema::Definition do
  describe ".attribute" do
    it "defines an attribute" do
      d = class_dsl { attribute :test }

      expect(d.attributes[:test]).to be < Schema::Attribute
    end

    it "sets options on the attribute from an option hash" do
      d = class_dsl { attribute :test, :visible => true, :value_type => :hash }
      expect(d.attributes[:test].options).to eq(:visible => true, :value_type => :hash)
    end

    it "sets options on the attribute from a block" do
      d =
        class_dsl do
          attribute :test do
            visible false
          end
        end
      expect(d.attributes[:test].options).to eq(:visible => false)
    end

    it "sets only the last options on the attribute from a block" do
      d =
        class_dsl do
          attribute :test do
            visible false
            visible true
          end
        end
      expect(d.attributes[:test].options).to eq(:visible => true)
    end

    it "doesn't set options on the attribute from a block when values are nil" do
      d =
        class_dsl do
          attribute :test do
            visible nil
          end
        end
      expect(d.attributes[:test].options).to be_empty
    end

    it "doesn't allow modification of the schema after its definition" do
      pending "Implement somehow?"
      d = class_dsl { attribute :test }
      expect do
        d.instance_eval { attribute :other }
      end.to raise_error(Schema::Error::FrozenError)
      expect(d.schema.attributes[:test]).to be_kind_of(Schema::Attribute)
      expect(d.schema.attributes[:other]).to be_nil
    end

    it "registers multiple checks" do
      custom_check = lambda {}
      d =
        class_dsl do
          attribute :test do
            check custom_check
            check custom_check
          end
        end
      expect(d.attributes[:test].checks).to eq([custom_check, custom_check])
    end

    it "defines nested attributes" do
      d =
        class_dsl do
          attribute :test do
            attribute :nested_test
          end
        end

      test_attribute = d.attributes[:test]
      expect(test_attribute.attributes[:nested_test]).to be <= Schema::Attribute
    end

    it "inherits attributes from superclass" do
      parent_definition = class_dsl { attribute :shared }
      d = class_dsl(parent_definition) { attribute :test }

      expect(d.attributes[:test]).to be <= Schema::Attribute
      expect(d.attributes[:shared]).to be <= Schema::Attribute
    end

    it "inherits plugins from superclass" do
      plugin1 = plugin_dsl { option :plug, :default_value => :abc }
      parent_definition =
        class_dsl do
          plugin plugin1
          attribute :shared
        end
      d = class_dsl(parent_definition) { attribute :test }

      test_attribute = d.attributes[:test]
      expect(test_attribute).to be <= Schema::Attribute
      expect(test_attribute.plugins).to contain_exactly(plugin1)
      expect(test_attribute.options).to include(:plug => :abc)

      shared_attribute = d.attributes[:shared]
      expect(shared_attribute).to be <= Schema::Attribute
      expect(shared_attribute.plugins).to contain_exactly(plugin1)
      expect(shared_attribute.options).to include(:plug => :abc)
    end

    it "defines attributes with schema" do
      nested_schema =
        class_dsl do
          attribute :class_test
        end
      d = class_dsl { attribute :test, nested_schema }

      test_attribute = d.attributes[:test]
      expect(test_attribute.attributes[:class_test]).to be <= Schema::Attribute
    end

    it "defines attributes with schema and inherits plugin options" do
      plug = plugin_dsl { option :plug_option }
      nested_definition =
        class_dsl do
          plugin plug

          option :plug_option, :plug
          attribute :class_test
        end
      d = class_dsl { attribute :test, nested_definition }

      test_attribute = d.attributes[:test]
      expect(test_attribute.options).to eq(:plug_option => :plug)
      expect(test_attribute.attributes[:class_test].options).to be_empty
    end

    it "defines attributes with schema and inherits plugin options from attributes" do
      plug = plugin_dsl { option :plug_option }
      nested_definition =
        class_dsl do
          plugin plug

          option :plug_option, :plug
          attribute :class_test, :plug_option => :attr
        end
      d = class_dsl { attribute :test, nested_definition }

      test_attribute = d.attributes[:test]
      expect(test_attribute.options).to eq(:plug_option => :plug)
      expect(test_attribute.attributes[:class_test].options).to eq(:plug_option => :attr)
    end

    it "defines attributes with schema and overrides inherited options" do
      plug = plugin_dsl { option :plug_option }
      nested_definition =
        class_dsl do
          plugin plug

          option :plug_option, :nested_plug
          attribute :class_test, :plug_option => :nested_attr
        end
      d = class_dsl { attribute :test, nested_definition, :plug_option => :override }

      test_attribute = d.attributes[:test]
      expect(test_attribute.options).to eq(:plug_option => :override)
      expect(test_attribute.attributes[:class_test].options).to eq(:plug_option => :nested_attr)
    end

    it "defines nested attributes with a schema class and overrides options" do
      plug = plugin_dsl { option :plug_option }
      nested_definition =
        class_dsl do
          plugin plug

          attribute :class_test
          attribute :class_test_with_plug, :plug_option => :attr
        end
      d =
        class_dsl do
          plugin plug

          attribute :test1, nested_definition, :plug_option => 1
          attribute :test2, nested_definition, :plug_option => 2 do
            option :plug_option, 3 # Block values is leading
          end
          attribute :test3, nested_definition # Has no plug_option
        end

      test_attribute1 = d.attributes[:test1]
      expect(test_attribute1.options[:plug_option]).to be(1)
      expect(test_attribute1.attributes[:class_test].options).to be_empty
      expect(test_attribute1.attributes[:class_test_with_plug].options).to eq(:plug_option => :attr)

      test_attribute2 = d.attributes[:test2]
      expect(test_attribute2.options[:plug_option]).to be(3)
      expect(test_attribute2.attributes[:class_test].options).to be_empty
      expect(test_attribute2.attributes[:class_test_with_plug].options).to eq(:plug_option => :attr)

      test_attribute3 = d.attributes[:test3]
      expect(test_attribute3.options).to be_empty
      expect(test_attribute3.attributes[:class_test].options).to be_empty
      expect(test_attribute3.attributes[:class_test_with_plug].options).to eq(:plug_option => :attr)
    end
  end

  describe ".plugin" do
    it "registers a plugin" do
      plugin1 = plugin_dsl
      d =
        class_dsl do
          plugin plugin1
          attribute :test do
            attribute :nested_test
          end
        end

      expect(d.plugins).to contain_exactly(plugin1)
      expect(d.attributes[:test].plugins).to contain_exactly(plugin1)
      expect(d.attributes[:test].attributes[:nested_test].plugins)
        .to contain_exactly(plugin1)
    end

    it "only registers a plugin once" do
      plugin1 = plugin_dsl
      d =
        class_dsl do
          plugin plugin1
          plugin plugin1
          attribute :test do
            attribute :nested_test
          end
        end

      expect(d.plugins).to contain_exactly(plugin1)
      expect(d.attributes[:test].plugins).to contain_exactly(plugin1)
      expect(d.attributes[:test].attributes[:nested_test].plugins)
        .to contain_exactly(plugin1)
    end

    it "only adds the plugin to the schema definition it registers on" do
      plugin1 = plugin_dsl
      d1 =
        class_dsl do
          plugin plugin1
          attribute :test
        end
      d2 = class_dsl { attribute :test }

      expect(d1.plugins).to contain_exactly(plugin1)
      expect(d1.attributes[:test].plugins).to contain_exactly(plugin1)
      expect(d2.plugins).to be_empty
      expect(d2.attributes[:test].plugins).to be_empty
    end

    it "adds options to attributes defined in the plugin" do
      plugin1 = plugin_dsl { option :my_option }
      d =
        class_dsl do
          plugin plugin1

          attribute :test1, :my_option => :value1
          attribute :test2 do
            option :my_option, :value2
          end
          attribute :test3 do
            option :my_option do
              :value3
            end
          end
        end

      expect(d.attributes[:test1].options[:my_option]).to eq(:value1)
      expect(d.attributes[:test2].options[:my_option]).to eq(:value2)
      expect(d.attributes[:test3].options[:my_option].call).to eq(:value3)
    end

    it "adds default options values to attributes defined in the plugin" do
      plugin1 = plugin_dsl { option :my_option, :default_value => :default }
      d =
        class_dsl do
          plugin plugin1
          attribute :test1
          attribute :test2, :my_option => :custom
        end

      expect(d.attributes[:test1].options[:my_option]).to eq(:default)
      expect(d.attributes[:test2].options[:my_option]).to eq(:custom)
    end

    it "adds methods to atttributes defined in the plugin" do
      plugin1 =
        plugin_dsl do
          helpers do
            def my_method(arg1, arg2)
              [:my_method, arg1, arg2]
            end
          end
        end
      d1 =
        class_dsl do
          plugin plugin1
          attribute :test
        end

      result = d1.new(:test => true)

      expect(result[:test].my_method(:abc, :def)).to eq([:my_method, :abc, :def])
    end
  end
end
