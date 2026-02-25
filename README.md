# CronBeats Ruby SDK (Ping)

[![Gem Version](https://img.shields.io/gem/v/cronbeats-ruby)](https://rubygems.org/gems/cronbeats-ruby)
[![Downloads](https://img.shields.io/gem/dt/cronbeats-ruby)](https://rubygems.org/gems/cronbeats-ruby)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%202.7-red)](https://rubygems.org/gems/cronbeats-ruby)

Official Ruby SDK for CronBeats ping telemetry.

## Install

```bash
gem install cronbeats-ruby
```

## Quick Usage

```ruby
require "cronbeats_ruby"

client = CronBeatsRuby::PingClient.new("abc123de")
client.start
# ...your work...
client.success
```

## Progress Updates

```ruby
client.progress(50, "Processing batch 50/100")

client.progress({
  seq: 75,
  message: "Almost done"
})
```

## Notes

- SDK uses `POST` for telemetry requests.
- `jobKey` must be exactly 8 Base62 characters.
- Retries happen only for network errors, HTTP `429`, and HTTP `5xx`.
- Default 5s timeout ensures the SDK never blocks your cron job if CronBeats is unreachable.
