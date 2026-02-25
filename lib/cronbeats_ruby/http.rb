require "json"
require "net/http"
require "uri"

module CronBeatsRuby
  class NetHttpClient
    def request(method:, url:, headers:, body:, timeout_ms:)
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      timeout = [timeout_ms.to_f / 1000.0, 0.001].max
      http.open_timeout = timeout
      http.read_timeout = timeout
      http.write_timeout = timeout if http.respond_to?(:write_timeout=)

      req = Net::HTTP.const_get(method.capitalize).new(uri.request_uri)
      headers.each { |k, v| req[k] = v }
      req.body = body unless body.nil?

      res = http.request(req)
      {
        status: res.code.to_i,
        body: res.body.to_s,
        headers: res.to_hash.transform_keys(&:downcase),
      }
    rescue StandardError => e
      raise SdkError, e.message
    end
  end
end
