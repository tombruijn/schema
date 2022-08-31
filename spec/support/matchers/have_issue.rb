# frozen_string_literal: true

RSpec::Matchers.define :have_error do |message|
  match do |actual_issues|
    actual_issues.any? do |issue|
      issue.type == :error && issue.message == message
    end
  end
end

RSpec::Matchers.define :have_warning do |message|
  match do |actual_issues|
    actual_issues.any? do |issue|
      issue.type == :warning && issue.message == message
    end
  end
end

RSpec::Matchers.define :have_note do |message|
  match do |actual_issues|
    actual_issues.any? do |issue|
      issue.type == :note && issue.message == message
    end
  end
end
