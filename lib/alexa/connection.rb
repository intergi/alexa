require "uri"
require "base64"
require "openssl"
require "digest/sha1"
require "faraday"
require "time"

module Alexa
  class Connection
    attr_accessor :secret_access_key, :access_key_id
    attr_writer :params

    AUTH_ALGORITHM  = "AWS4-HMAC-SHA256"
    RFC_3986_REGEXP = /[^A-Za-z0-9\-_.~]/

    def initialize(credentials = {})
      self.secret_access_key = credentials.fetch(:secret_access_key)
      self.access_key_id     = credentials.fetch(:access_key_id)
    end

    def params
      @params ||= {}
    end

    def get(params = {})
      self.params = params
      handle_response(request).body.force_encoding(Encoding::UTF_8)
    end

    def signature
      OpenSSL::HMAC.hexdigest('sha256', signature_key, string_to_sign)
    end

    def query
      params.map do |key, value|
        "#{key}=#{URI.escape(value.to_s, RFC_3986_REGEXP)}"
      end.sort.join("&")
    end

    private

    def handle_response(response)
      case response.status.to_i
      when 200...300
        response
      when 300...600
        if response.body.nil?
          raise ResponseError.new(nil, response)
        else
          xml = MultiXml.parse(response.body)
          message = xml["Response"]["Errors"]["Error"]["Message"]
          raise ResponseError.new(message, response)
        end
      else
        raise ResponseError.new("Unknown code: #{respnse.code}", response)
      end
    end

    def request
      Faraday.get do |req|
        req.url url
        req.headers = request_headers
      end
    end

    def timestamp
      @timestamp ||= Time::now.utc.strftime("%Y%m%dT%H%M%SZ")
    end

    def datestamp
      @datestamp ||= Time::now.utc.strftime("%Y%m%d")
    end

    def url
      "https://#{Alexa::API_HOST}#{Alexa::API_URI}?#{query}"
    end

    def headers
      {
        "host"        => Alexa::SERVICE_ENDPOINT,
        "x-amz-date"  => timestamp
      }
    end

    def request_headers
      {
        "Accept"        => "application/xml",
        "Content-Type"  => "application/xml",
        "x-amz-date"    => timestamp,
        "Authorization" => authorization_header
      }
    end

    def headers_str
      headers.sort.map { |k,v| "#{k}:#{v}" }.join("\n") + "\n"
    end

    def headers_lst
      headers.sort.map { |k,v| k }.join(";")
    end

    def payload_hash
      Digest::SHA256.hexdigest ""
    end

    def canonical_request
      @canonical_request ||= [
        "GET", Alexa::API_URI, query,
        headers_str, headers_lst, payload_hash
      ].join("\n")
    end

    def credential_scope
      @credential_scope ||= [
        datestamp, Alexa::SERVICE_REGION, Alexa::SERVICE_NAME, "aws4_request"
      ].join('/')
    end

    def string_to_sign
      @string_to_sign ||= [
        AUTH_ALGORITHM, timestamp, credential_scope,
        Digest::SHA256.hexdigest(canonical_request)
      ].join("\n")
    end

    def signature_key
      kdate    = OpenSSL::HMAC.digest('sha256', "AWS4" + self.secret_access_key, datestamp)
      kregion  = OpenSSL::HMAC.digest('sha256', kdate, Alexa::SERVICE_REGION)
      kservice = OpenSSL::HMAC.digest('sha256', kregion, Alexa::SERVICE_NAME)
      OpenSSL::HMAC.digest('sha256', kservice, "aws4_request")
    end

    def authorization_header
      "#{AUTH_ALGORITHM} Credential=#{self.access_key_id}/#{credential_scope}, SignedHeaders=#{headers_lst}, Signature=#{signature}"
    end
  end
end
