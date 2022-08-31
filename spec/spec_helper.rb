# frozen_string_literal: true

if ENV["COV"]
  require "simplecov"
  SimpleCov.start
end

PROJECT_DIR = File.expand_path(__dir__, "../")
SPEC_DIR = __dir__
LIB_DIR = File.join(PROJECT_DIR, "lib")

$LOAD_PATH.unshift(LIB_DIR)
require "schema"

Dir.glob(File.join(SPEC_DIR, "helpers/**/*.rb")).sort.each do |file|
  require file
end
Dir.glob(File.join(SPEC_DIR, "support/**/*.rb")).sort.each do |file|
  require file
end

RSpec.configure do |config|
  config.include DSLHelper
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.example_status_persistence_file_path = "spec/examples.txt"

  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.profile_examples = 10

  config.order = :random
  Kernel.srand config.seed
end
