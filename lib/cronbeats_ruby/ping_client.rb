require "json"

module CronBeatsRuby
  class PingClient
    def initialize(job_key, options = {})
      assert_job_key(job_key)

      @job_key = job_key
      @base_url = (options[:base_url] || "https://cronbeats.io").to_s.sub(%r{/+$}, "")
      @timeout_ms = Integer(options[:timeout_ms] || 5000)
      @max_retries = Integer(options[:max_retries] || 2)
      @retry_backoff_ms = Integer(options[:retry_backoff_ms] || 250)
      @retry_jitter_ms = Integer(options[:retry_jitter_ms] || 100)
      @user_agent = (options[:user_agent] || "cronbeats-ruby-sdk/0.1.0").to_s
      @http_client = options[:http_client] || NetHttpClient.new
    end

    def ping
      request("ping", "/ping/#{@job_key}")
    end

    def start
      request("start", "/ping/#{@job_key}/start")
    end

    def end(status = "success")
      status_value = status.to_s.strip.downcase
      unless %w[success fail].include?(status_value)
        raise ValidationError, 'Status must be "success" or "fail".'
      end

      request("end", "/ping/#{@job_key}/end/#{status_value}")
    end

    def success
      self.end("success")
    end

    def fail
      self.end("fail")
    end

    def progress(seq_or_options = nil, message = nil)
      seq = nil
      msg = message

      if seq_or_options.is_a?(Integer)
        seq = seq_or_options
      elsif seq_or_options.is_a?(Hash)
        seq = seq_or_options.key?(:seq) ? Integer(seq_or_options[:seq]) : nil
        msg = (seq_or_options[:message] || msg || "").to_s
      end

      if !seq.nil? && seq.negative?
        raise ValidationError, "Progress seq must be a non-negative integer."
      end

      safe_msg = (msg || "").to_s
      safe_msg = safe_msg[0, 255] if safe_msg.length > 255

      unless seq.nil?
        return request("progress", "/ping/#{@job_key}/progress/#{seq}", { message: safe_msg })
      end

      body = { message: safe_msg }
      body[:progress] = seq_or_options if seq_or_options.is_a?(Integer)
      request("progress", "/ping/#{@job_key}/progress", body)
    end

    private

    def request(action, path, body = {})
      attempt = 0
      url = "#{@base_url}#{path}"

      payload =
        begin
          body.empty? ? nil : JSON.generate(body)
        rescue StandardError
          raise SdkError, "Failed to encode request payload."
        end

      loop do
        begin
          response = @http_client.request(
            method: "post",
            url: url,
            headers: {
              "Content-Type" => "application/json",
              "Accept" => "application/json",
              "User-Agent" => @user_agent,
            },
            body: payload,
            timeout_ms: @timeout_ms
          )
        rescue SdkError => e
          if attempt >= @max_retries
            raise ApiError.new(
              code: "NETWORK_ERROR",
              http_status: nil,
              retryable: true,
              message: e.message,
              raw: e
            )
          end

          attempt += 1
          sleep_with_backoff(attempt)
          next
        end

        status = response[:status].to_i
        decoded = safe_json(response[:body].to_s)

        if status >= 200 && status < 300
          return normalize_success(action, decoded)
        end

        error = map_error(status)
        if error[:retryable] && attempt < @max_retries
          attempt += 1
          sleep_with_backoff(attempt)
          next
        end

        raise ApiError.new(
          code: error[:code],
          http_status: status,
          retryable: error[:retryable],
          message: (decoded["message"] || "Request failed").to_s,
          raw: decoded
        )
      end
    end

    def normalize_success(action, payload)
      {
        "ok" => true,
        "action" => (payload["action"] || action).to_s,
        "jobKey" => (payload["job_key"] || @job_key).to_s,
        "timestamp" => (payload["timestamp"] || "").to_s,
        "processingTimeMs" => float_or_zero(payload["processing_time_ms"]),
        "nextExpected" => payload.key?("next_expected") ? payload["next_expected"]&.to_s : nil,
        "raw" => payload,
      }
    end

    def map_error(status)
      return { code: "VALIDATION_ERROR", retryable: false } if status == 400
      return { code: "NOT_FOUND", retryable: false } if status == 404
      return { code: "RATE_LIMITED", retryable: true } if status == 429
      return { code: "SERVER_ERROR", retryable: true } if status >= 500

      { code: "UNKNOWN_ERROR", retryable: false }
    end

    def assert_job_key(job_key)
      return if /\A[a-zA-Z0-9]{8}\z/.match?(job_key.to_s)

      raise ValidationError, "jobKey must be exactly 8 Base62 characters."
    end

    def sleep_with_backoff(attempt)
      base_ms = @retry_backoff_ms * (2**[attempt - 1, 0].max)
      jitter_ms = rand(0..[@retry_jitter_ms, 0].max)
      Kernel.sleep((base_ms + jitter_ms) / 1000.0)
    end

    def safe_json(raw)
      parsed = JSON.parse(raw)
      return parsed if parsed.is_a?(Hash)
    rescue JSON::ParserError
      nil
    ensure
      return({ "message" => "Invalid JSON response" }) if defined?(parsed).nil? || !parsed.is_a?(Hash)
    end

    def float_or_zero(value)
      Float(value)
    rescue StandardError
      0.0
    end
  end
end
