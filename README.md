# Schema

Work in progress Schema definition DSL gem.

## Example

```ruby
class MyOtherSchema < Schema::Definition
  attribute :other_attribute
end

class MySchema < Schema::Definition
  attribute :nested_section do
    attribute :nested_attribute do
      check do |attr|
        next unless attr.value

        attr.add_error "is not set"
      end
    end
  end
  attribute :class_section, MyOtherSchema
end
```
