# frozen_string_literal: true

require_relative "lib/schema/version"

REPO_URL = "https://github.com/tombruijn/schema"

Gem::Specification.new do |s|
  s.name        = "schema"
  s.version     = Schema::VERSION
  s.licenses    = ["MIT"]
  s.summary     = "Schema definition" # TODO
  s.description = "Schema definition" # TODO
  s.authors     = ["Tom de Bruijn"]
  s.email       = "tom@tomdebruijn.com"
  s.files       = Dir["README.md", "LICENSE.md", "CHANGELOG.md", "lib/**/*"]
  s.homepage    = REPO_URL
  s.metadata    = {
    "source_code_uri" => REPO_URL,
    "bug_tracker_uri" => "#{REPO_URL}/issues",
    "changelog_uri" => "#{REPO_URL}/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true"
  }
  s.required_ruby_version = ">= 2.7.0"

  s.add_development_dependency "rspec", "~> 3.11"
  s.add_development_dependency "rubocop", "1.36.0"
  s.add_development_dependency "simplecov", "~> 0.21"
end
