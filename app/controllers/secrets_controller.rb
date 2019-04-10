# frozen_string_literal: true

class SecretsController < ApplicationController
  before_action :authenticate

  TOKEN = "53b43d27f7d25fa0a6f109119157b216"

  def show
    head :ok
  end

  private

  def authenticate
    authenticate_or_request_with_http_token do |token|
      # TOKEN == token
      equal?(TOKEN, token)
      # secure_compare(TOKEN, token)
    end
  end

  def equal?(str1, str2)
    chars1 = str1.chars
    chars2 = str2.chars

    while a = chars1.shift
      b = chars2.shift

      if a && a == b
        # hey we got a match! let's check the next
        sleep(0.01)
      else
        return false
      end
    end

    if (chars1.length + chars2.length) > 0
      false
    else
      true
    end
  end

  def constant_time_equal?(str1, str2)
    str1_bytes = str1.unpack("C#{str1.bytesize}")
    result = 0
    # bitwise XOR bytes, if they're different then bitwise OR into the result
    str2.each_byte { |byte| result |= byte ^ str1_bytes.shift }
    result.zero?
  end

  def hash_digest(str)
    Digest::SHA256.hexdigest(str)
  end

  def secure_compare(str1, str2)
    constant_time_equal?(hash_digest(str1), hash_digest(str2)) && str1 == str2
  end
end
