# frozen_string_literal: true

RSpec.describe Schema::Attribute do
  let(:schema) do
    class_dsl do
      attribute :symbol_key
      attribute :nested_section do
        attribute :nested_key
      end
    end
  end
  let(:parsed_result) { schema.new }

  describe "#path" do
    it "returns the full path of the attribute" do
      expect(parsed_result[:symbol_key].path).to eq([:symbol_key])
    end

    context "with nested attribute" do
      it "returns the full path of the attribute" do
        expect(parsed_result[:nested_section][:nested_key].path)
          .to eq([:nested_section, :nested_key])
      end
    end
  end

  describe "#full_path" do
    it "returns a string representation of #path" do
      expect(parsed_result[:symbol_key].full_path).to eq("symbol_key")
    end

    context "with nested attribute" do
      it "returns the full path of the attribute" do
        expect(parsed_result[:nested_section][:nested_key].full_path)
          .to eq("nested_section.nested_key")
      end
    end
  end

  describe "#name" do
    it "returns name/key of the attribute" do
      expect(parsed_result[:symbol_key].name).to eq(:symbol_key)
    end

    context "with nested attribute" do
      it "returns name/key of the attribute" do
        expect(parsed_result[:nested_section][:nested_key].name)
          .to eq(:nested_key)
      end
    end
  end
end
