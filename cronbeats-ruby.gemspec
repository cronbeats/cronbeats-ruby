require_relative "lib/cronbeats_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "cronbeats-ruby"
  spec.version = CronBeatsRuby::VERSION
  spec.authors = ["CronBeats"]
  spec.email = ["support@cronbeats.com"]

  spec.summary = "Official CronBeats Ping SDK for Ruby."
  spec.description = "Ruby client for CronBeats ping, start/end, and progress telemetry APIs."
  spec.homepage = "https://github.com/cronbeats/cronbeats-ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/cronbeats/cronbeats-ruby",
    "bug_tracker_uri" => "https://github.com/cronbeats/cronbeats-ruby/issues",
  }

  spec.files = Dir.glob("{lib,spec}/**/*") + %w[README.md LICENSE Gemfile]
  spec.require_paths = ["lib"]
end
