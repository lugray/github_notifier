require 'octobox_notifier'
require 'net/http'

module OctoboxNotifier
  module API
    class << self
      def start(&block)
        host = OctoboxNotifier::Config.get("server", "host")
        Net::HTTP.start(host, 443, use_ssl: true, &block)
      end

      def get(url, headers = {})
        start do |http|
          resp = http.get(url, default_headers.merge(headers))
          raise(CLI::Kit::Abort, "Cannot access octobox: #{resp}") unless resp.code.to_i == 200
          resp
        end
      end

      def post(url, data, headers = {})
        start do |http|
          resp = http.post(url, data, default_headers.merge(headers))
          raise(CLI::Kit::Abort, "Cannot access octobox: #{resp}") unless resp.code.to_i == 200
          resp
        end
      end

      def default_headers
        {
          'Authorization' => "Bearer #{OctoboxNotifier::Config.get("server", "token")}",
          "X-Octobox-API" => "1",
        }
      end
    end
  end
end
