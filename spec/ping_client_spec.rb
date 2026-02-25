require "json"
require "cronbeats_ruby"

RSpec.describe CronBeatsRuby::PingClient do
  class StubHttpClient
    attr_reader :calls

    def initialize(responses: [], network_failures: 0)
      @responses = responses
      @network_failures = network_failures
      @calls = []
    end

    def request(method:, url:, headers:, body:, timeout_ms:)
      @calls << { method: method, url: url, body: body, timeout_ms: timeout_ms, headers: headers }

      if @network_failures.positive?
        @network_failures -= 1
        raise CronBeatsRuby::SdkError, "socket timeout"
      end

      @responses.shift || { status: 200, body: "{}", headers: {} }
    end
  end

  it "rejects invalid job key" do
    expect { described_class.new("invalid-key") }.to raise_error(CronBeatsRuby::ValidationError)
  end

  it "normalizes success response" do
    stub = StubHttpClient.new(
      responses: [
        {
          status: 200,
          body: JSON.generate(
            {
              status: "success",
              message: "OK",
              action: "ping",
              job_key: "abc123de",
              timestamp: "2026-02-25 12:00:00",
              processing_time_ms: 8.25,
            }
          ),
          headers: {},
        },
      ]
    )
    client = described_class.new("abc123de", http_client: stub)
    result = client.ping
    expect(result["ok"]).to eq(true)
    expect(result["action"]).to eq("ping")
    expect(result["jobKey"]).to eq("abc123de")
    expect(result["processingTimeMs"]).to eq(8.25)
  end

  it "maps 404 to NOT_FOUND" do
    stub = StubHttpClient.new(
      responses: [
        { status: 404, body: JSON.generate({ status: "error", message: "Job not found" }), headers: {} },
      ]
    )
    client = described_class.new("abc123de", http_client: stub, max_retries: 0)
    expect { client.ping }.to raise_error(CronBeatsRuby::ApiError) { |err|
      expect(err.code).to eq("NOT_FOUND")
      expect(err.retryable).to eq(false)
      expect(err.http_status).to eq(404)
    }
  end

  it "retries on 429 and then succeeds" do
    stub = StubHttpClient.new(
      responses: [
        { status: 429, body: JSON.generate({ status: "error", message: "Too many requests" }), headers: {} },
        {
          status: 200,
          body: JSON.generate(
            {
              status: "success",
              message: "OK",
              action: "ping",
              job_key: "abc123de",
              timestamp: "2026-02-25 12:00:00",
              processing_time_ms: 7.1,
            }
          ),
          headers: {},
        },
      ]
    )
    client = described_class.new(
      "abc123de",
      http_client: stub,
      max_retries: 2,
      retry_backoff_ms: 1,
      retry_jitter_ms: 0
    )
    result = client.ping
    expect(result["ok"]).to eq(true)
    expect(stub.calls.length).to eq(2)
  end

  it "does not retry on 400" do
    stub = StubHttpClient.new(
      responses: [
        { status: 400, body: JSON.generate({ status: "error", message: "Invalid request" }), headers: {} },
      ]
    )
    client = described_class.new("abc123de", http_client: stub, max_retries: 2)
    expect { client.ping }.to raise_error(CronBeatsRuby::ApiError) { |err|
      expect(err.code).to eq("VALIDATION_ERROR")
      expect(err.retryable).to eq(false)
    }
    expect(stub.calls.length).to eq(1)
  end

  it "retries on network errors and then succeeds" do
    stub = StubHttpClient.new(
      responses: [
        {
          status: 200,
          body: JSON.generate(
            {
              status: "success",
              message: "OK",
              action: "ping",
              job_key: "abc123de",
              timestamp: "2026-02-25 12:00:00",
              processing_time_ms: 4.2,
            }
          ),
          headers: {},
        },
      ],
      network_failures: 1
    )
    client = described_class.new(
      "abc123de",
      http_client: stub,
      max_retries: 2,
      retry_backoff_ms: 1,
      retry_jitter_ms: 0
    )
    result = client.ping
    expect(result["ok"]).to eq(true)
    expect(stub.calls.length).to eq(2)
  end

  it "normalizes progress and truncates message to 255" do
    stub = StubHttpClient.new(
      responses: [
        {
          status: 200,
          body: JSON.generate(
            {
              status: "success",
              message: "OK",
              action: "progress",
              job_key: "abc123de",
              timestamp: "2026-02-25 12:00:00",
              processing_time_ms: 8,
            }
          ),
          headers: {},
        },
      ]
    )
    long_msg = "x" * 300
    client = described_class.new("abc123de", http_client: stub)
    client.progress({ seq: 50, message: long_msg })
    expect(stub.calls[0][:url]).to end_with("/ping/abc123de/progress/50")
    sent = JSON.parse(stub.calls[0][:body])
    expect(sent["message"].length).to eq(255)
  end
end
