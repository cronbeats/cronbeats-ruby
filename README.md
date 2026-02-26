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

## Progress Tracking

Track your job's progress in real-time. CronBeats supports two distinct modes:

### Mode 1: With Percentage (0-100)
Shows a **progress bar** and your status message on the dashboard.

✓ **Use when**: You can calculate meaningful progress (e.g., processed 750 of 1000 records)

```ruby
# Percentage mode: 0-100 with message
client.progress(50, "Processing batch 500/1000")

# Or using hash
client.progress({
  seq: 75,
  message: "Almost done - 750/1000"
})
```

### Mode 2: Message Only
Shows **only your status message** (no percentage bar) on the dashboard.

✓ **Use when**: Progress isn't measurable or you only want to send status updates

```ruby
# Message-only mode: nil seq, just status updates
client.progress(nil, "Connecting to database...")
client.progress(nil, "Starting data sync...")
```

### What you see on the dashboard
- **Mode 1**: Progress bar (0-100%) + your message → "75% - Processing batch 750/1000"
- **Mode 2**: Only your status message → "Connecting to database..."

### Complete Example

```ruby
require "cronbeats_ruby"

client = CronBeatsRuby::PingClient.new("abc123de")
client.start

begin
  # Message-only updates for non-measurable steps
  client.progress(nil, "Connecting to database...")
  db = connect_to_database
  
  client.progress(nil, "Fetching records...")
  total = db.count
  
  # Percentage updates for measurable progress
  (0...total).each do |i|
    process_record(i)
    
    if (i % 100).zero?
      percent = (i * 100 / total).to_i
      client.progress(percent, "Processed #{i} / #{total} records")
    end
  end
  
  client.progress(100, "All records processed")
  client.success
  
rescue => e
  client.fail
  raise
end
```

## Notes

- SDK uses `POST` for telemetry requests.
- `jobKey` must be exactly 8 Base62 characters.
- Retries happen only for network errors, HTTP `429`, and HTTP `5xx`.
- Default 5s timeout ensures the SDK never blocks your cron job if CronBeats is unreachable.
