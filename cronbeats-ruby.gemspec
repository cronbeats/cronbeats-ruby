require_relative "lib/cronbeats_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "cronbeats-ruby"
  spec.version = CronBeatsRuby::VERSION
  spec.authors = ["CronBeats"]
  spec.email = ["support@cronbeats.com"]

  spec.summary = "Cron job monitoring and heartbeat monitoring SDK for Ruby."
  spec.description = "Cron job monitoring and heartbeat monitoring SDK for Ruby. Monitor scheduled tasks, background jobs, and cron jobs with simple ping telemetry. Get alerts when cron jobs fail, miss their schedule, or run too long."
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
