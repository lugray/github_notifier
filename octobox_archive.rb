#!/usr/ruby

require 'net/http'
require 'open3'

def fail(msg)
  puts "💥#{msg}"
  exit 1
end

token, _, t = Open3.capture3('security', 'find-generic-password', '-w', '-l', 'octobox-token')
fail 'Cannot retrieve token' unless t.success?

notifications = Net::HTTP.start('octobox.shopify.io', 443, use_ssl: true) do |http|
  resp = http.post("/notifications/archive_selected.json", "id[]=#{ARGV[0]}&value=true", 'Authorization' => "Bearer #{token}", "X-Octobox-API" => "1")
  fail "Cannot access octobox: #{resp}" unless resp.code.to_i == 200
end
