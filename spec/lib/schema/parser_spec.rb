# frozen_string_literal: true

RSpec.describe Schema::Definition do
  describe ".new" do
    it "parses a Ruby Hash with mixed key types" do
      d =
        class_dsl do
          attribute :symbol_key do
            check do |attr|
              attr.add_error "My symbol attribute error"
            end
          end
          attribute "string_definition_key" do
            check do |attr|
              attr.add_error "My string attribute error"
            end
          end
          attribute :string_value_key do
            check do |attr|
              attr.add_error "My string attribute error"
            end
          end
        end

      result = d.new(
        :symbol_key => "symbol value",
        :string_definition_key => "string value",
        "string_value_key" => "string value"
      )
      result.check!
      expect(result.valid?).to be(false)

      symbol_attr = result[:symbol_key]
      expect(symbol_attr.name).to eq(:symbol_key)
      expect(symbol_attr.full_path).to eq("symbol_key")
      expect(symbol_attr.value).to eq("symbol value")
      expect(symbol_attr.valid?).to be(false)
      expect(symbol_attr.issues).to have_error("My symbol attribute error")

      string_definition_attr = result[:string_definition_key]
      expect(string_definition_attr.name).to eq(:string_definition_key)
      expect(string_definition_attr.full_path).to eq("string_definition_key")
      expect(string_definition_attr.value).to eq("string value")
      expect(string_definition_attr.valid?).to be(false)
      expect(string_definition_attr.issues).to have_error("My string attribute error")

      string_value_attr = result[:string_value_key]
      expect(string_value_attr.name).to eq(:string_value_key)
      expect(string_value_attr.full_path).to eq("string_value_key")
      expect(string_value_attr.value).to eq("string value")
      expect(string_value_attr.valid?).to be(false)
      expect(string_value_attr.issues).to have_error("My string attribute error")
    end

    it "parses unknown attribute" do
      d = class_dsl { attribute :symbol_key }

      result = d.new(
        :symbol_key => "symbol value",
        :unknown_key => "some value",
        :unknown_section => {
          :unknown_nested_key => "other value",
          :unknown_nested_section => { :unknown_nested_section_key => "other value" }
        }
      )
      result.check!

      expect(result[:symbol_key]).to_not be_nil

      unknown_attr = result[:unknown_key]
      expect(unknown_attr.value).to eq("some value")
      expect(unknown_attr.valid?).to be(true)
      expect(unknown_attr.unknown?).to be(true)

      unknown_section = result[:unknown_section]
      expect(unknown_section.value).to eq(
        :unknown_nested_section => { :unknown_nested_section_key => "other value" },
        :unknown_nested_key => "other value"
      )
      expect(unknown_section.valid?).to be(true)
      expect(unknown_section.unknown?).to be(true)
    end

    it "can call methods defined in the same attribute" do
      d =
        class_dsl do
          attribute :test do
            check do |attr|
              hello(attr)
            end

            def hello(attr)
              attr.add_note "hello"
            end
          end
        end

      result = d.new(:test => "value")
      result.check!
      expect(result[:test].issues).to have_note("hello")
    end

    it "parses nested data structures" do
      d =
        class_dsl do
          attribute :root_level_key do
            attribute :second_level_key do
              attribute :third_level_key1
              attribute :third_level_key2
            end
          end
        end

      result = d.new(
        :root_level_key => {
          :second_level_key => {
            :third_level_key1 => "value 1",
            :third_level_key2 => "value 2"
          }
        }
      )
      result.check!

      root_attr = result[:root_level_key]
      expect(root_attr.name).to eq(:root_level_key)
      expect(root_attr.full_path).to eq("root_level_key")
      expect(root_attr.value).to eq(
        :second_level_key => {
          :third_level_key1 => "value 1",
          :third_level_key2 => "value 2"
        }
      )

      second_level_attr = root_attr[:second_level_key]
      expect(second_level_attr.name).to eq(:second_level_key)
      expect(second_level_attr.full_path).to eq("root_level_key.second_level_key")
      expect(second_level_attr.value).to eq(
        :third_level_key1 => "value 1",
        :third_level_key2 => "value 2"
      )

      third_level_attr = second_level_attr[:third_level_key1]
      expect(third_level_attr.name).to eq(:third_level_key1)
      expect(third_level_attr.full_path).to eq("root_level_key.second_level_key.third_level_key1")
      expect(third_level_attr.value).to eq("value 1")

      third_level_attr = second_level_attr[:third_level_key2]
      expect(third_level_attr.name).to eq(:third_level_key2)
      expect(third_level_attr.full_path).to eq("root_level_key.second_level_key.third_level_key2")
      expect(third_level_attr.value).to eq("value 2")
    end

    describe "plugins" do
      it "runs plugin checks on only attributes with plugins option" do
        plugin1 =
          plugin_dsl do
            option :plug_option
            check { |attr| attr.add_note "From plugin 1" }
          end
        d =
          class_dsl do
            plugin plugin1

            attribute :id, :plug_option => 1
            attribute :name
          end

        result = d.new(
          :id => 123,
          :name => "Tom"
        )
        result.check!

        id_attr = result[:id]
        expect(id_attr.class.plugins).to contain_exactly(plugin1)
        expect(id_attr.class.options).to include(:plug_option => 1)
        expect(id_attr.issues).to have_note("From plugin 1")

        name_attr = result[:name]
        expect(name_attr.class.plugins).to contain_exactly(plugin1)
        expect(name_attr.class.options).to be_empty
        expect(name_attr.issues).to be_empty
      end

      it "runs plugin checks on all attributes when plugin has default option value" do
        plugin1 =
          plugin_dsl do
            option :plug_option, :default_value => :something
            check { |attr| attr.add_note "From plugin 1" }
          end
        d =
          class_dsl do
            plugin plugin1

            attribute :id, :plug_option => 1
            attribute :name
          end

        result = d.new(
          :id => 123,
          :name => "Tom"
        )
        result.check!

        id_attr = result[:id]
        expect(id_attr.class.plugins).to contain_exactly(plugin1)
        expect(id_attr.class.options).to include(:plug_option => 1)
        expect(id_attr.value).to eq(123)
        expect(id_attr.issues).to have_note("From plugin 1")

        name_attr = result[:name]
        expect(name_attr.class.plugins).to contain_exactly(plugin1)
        expect(name_attr.class.options).to include(:plug_option => :something)
        expect(name_attr.value).to eq("Tom")
        expect(name_attr.issues).to have_note("From plugin 1")
      end

      it "passes options to plugin checks" do
        plugin1 =
          plugin_dsl do
            option :plug_option, :default_value => :something
            check { |attr, plug_option:| attr.add_note "plug_option: #{plug_option}" }
          end
        d =
          class_dsl do
            plugin plugin1

            attribute :id, :plug_option => 1
          end

        result = d.new(:id => 123)
        result.check!

        id_attr = result[:id]
        expect(id_attr.issues).to have_note("plug_option: 1")
      end

      it "does not error if an unknown plugin option is specified a check argument" do
        plugin1 =
          plugin_dsl do
            option :plug_option, :default_value => :something
            check do |attr, unknown_option:|
              attr.add_note "unknown_option: #{unknown_option.inspect}"
            end
          end
        d =
          class_dsl do
            plugin plugin1

            attribute :id, :plug_option => 1
          end

        result = d.new(:id => 123)
        result.check!

        id_attr = result[:id]
        expect(id_attr.issues).to have_note("unknown_option: nil")
      end

      it "errors if the check errors" do
        plugin1 =
          plugin_dsl do
            option :plug_option, :default_value => :something
            check { |_attr| raise "uh oh" }
          end
        d =
          class_dsl do
            plugin plugin1
            attribute :id, :plug_option => 1
          end

        result = d.new(:id => 123)
        expect do
          result.check!
        end.to raise_error(Schema::Error::CheckFailedError, "Attribute check failed for '__root__'")
      end
    end

    it "parses attributes with class attributes" do
      plugin1 =
        plugin_dsl do
          option :plug_option1
          check { |attr| attr.add_note "From plugin 1" }
        end
      plugin2 =
        plugin_dsl do
          option :plug_option2
          check { |attr| attr.add_note "From plugin 2" }
        end
      address_definition =
        class_dsl do
          plugin plugin2

          plug_option2 2
          attribute :street_name
          attribute :number, :plug_option2 => 3
        end
      socials_definition = class_dsl { attribute :github }
      d =
        class_dsl do
          plugin plugin1

          attribute :id, :plug_option1 => 1
          attribute :address, address_definition
          attribute :socials, socials_definition
        end

      result = d.new(
        :id => 123,
        :name => "Tom",
        :address => {
          :street_name => "Teststreet",
          :number => 101
        },
        :socials => {
          :github => "tombruijn"
        }
      )
      result.check!

      id_attr = result[:id]
      expect(id_attr.class.plugins).to contain_exactly(plugin1)
      expect(id_attr.class.options).to include(:plug_option1 => 1)
      expect(id_attr.value).to eq(123)
      expect(id_attr.issues).to have_note("From plugin 1")

      address_attr = result[:address]
      expect(address_attr.class.plugins).to contain_exactly(plugin2)
      expect(address_attr.class.options).to include(:plug_option2 => 2)
      expect(address_attr.value).to eq(:street_name => "Teststreet", :number => 101)
      expect(address_attr.issues).to have_note("From plugin 2")

      street_name_attr = address_attr[:street_name]
      expect(street_name_attr.class.plugins).to contain_exactly(plugin2)
      expect(street_name_attr.class.options).to be_empty
      expect(street_name_attr.value).to eq("Teststreet")
      expect(street_name_attr.issues).to be_empty

      house_number_attr = address_attr[:number]
      expect(house_number_attr.class.plugins).to contain_exactly(plugin2)
      expect(house_number_attr.class.options).to include(:plug_option2 => 3)
      expect(house_number_attr.value).to eq(101)
      expect(house_number_attr.issues).to have_note("From plugin 2")

      socials_attr = result[:socials]
      expect(socials_attr.class.plugins).to be_empty
      expect(socials_attr.class.options).to be_empty
      expect(socials_attr.value).to eq(:github => "tombruijn")
      expect(socials_attr.issues).to be_empty

      github_attr = socials_attr[:github]
      expect(github_attr.class.plugins).to be_empty
      expect(github_attr.class.options).to be_empty
      expect(github_attr.value).to eq("tombruijn")
      expect(github_attr.issues).to be_empty
    end

    it "pattern matches" do
      d = class_dsl { attribute :symbol_key }

      result = d.new(
        :symbol_key => "symbol value",
        :unknown_key => "some value",
        :unknown_section => {
          :unknown_nested_key => "other value",
          :unknown_nested_section => { :unknown_nested_section_key => "other value" }
        }
      )
      result.check!

      case result
      in { symbol_key: symbol_value }
        expect(symbol_value.value).to eq("symbol value")
      else
        # :nocov:
        raise "Did not match"
        # :nocov:
      end

      case result
      in { unknown_key: unknown_value }
        expect(unknown_value.value).to eq("some value")
      else
        # :nocov:
        raise "Did not match"
        # :nocov:
      end

      case result
      in { unknown_section: unknown_section_value }
        expect(unknown_section_value.value).to eq(
          :unknown_nested_key => "other value",
          :unknown_nested_section => { :unknown_nested_section_key => "other value" }
        )
      else
        # :nocov:
        raise "Did not match"
        # :nocov:
      end

      result in { unknown_section:, **rest }
      expect(rest[:symbol_key].value).to eq("symbol value")
      expect(rest[:unknown_key].value).to eq("some value")
    end
  end
end
