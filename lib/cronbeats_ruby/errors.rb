module CronBeatsRuby
  class SdkError < StandardError
  end

  class ValidationError < SdkError
  end

  class ApiError < SdkError
    attr_reader :code, :http_status, :retryable, :raw

    def initialize(code:, message:, http_status: nil, retryable: false, raw: nil)
      super(message)
      @code = code
      @http_status = http_status
      @retryable = retryable
      @raw = raw
    end
  end
end
