require 'github_notifier'
require 'net/http'

module GithubNotifier
  module API
    class << self
      def start(&block)
        host = GithubNotifier::Config.get("server", "host")
        Net::HTTP.start(host, 443, use_ssl: true, &block)
      end

      def get(url, headers = {})
        start do |http|
          resp = http.get(url, default_headers.merge(headers))
          raise(CLI::Kit::Abort, "Cannot access GitHub: #{resp}") unless resp.code.to_i < 400
          resp
        end
      end

      def post(url, data, headers = {})
        start do |http|
          resp = http.post(url, data, default_headers.merge(headers))
          raise(CLI::Kit::Abort, "Cannot access GitHub: #{resp}") unless resp.code.to_i < 400
          resp
        end
      end

      def default_headers
        {
          'Authorization' => "Bearer #{GithubNotifier::Config.get("server", "token")}",
        }
      end
    end
  end
end
