# Release Checklist

Use this checklist for each Ruby SDK release.

## Pre-release

- Run tests: `bundle exec rspec`
- Build gem: `gem build cronbeats-ruby.gemspec`
- Validate gem metadata and packaging output
- Confirm README examples still match current SDK behavior

## Release

- Commit changes on `main`
- Bump version in `lib/cronbeats_ruby/version.rb`
- Create tag: `git tag vX.Y.Z`
- Push branch and tag
- Publish gem: `gem push cronbeats-ruby-X.Y.Z.gem`

## Post-release

- Verify install in clean directory: `gem install cronbeats-ruby -v X.Y.Z`
- Run quick smoke call with `PingClient`
