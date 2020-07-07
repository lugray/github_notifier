require 'github_notifier'
require 'net/http'
require 'fileutils'

module GithubNotifier
  module API
    class << self
      def start(&block)
        Net::HTTP.start('api.github.com', 443, use_ssl: true, &block)
      end

      def get(url, headers = {})
        start do |http|
          resp = http.get(url, default_headers.merge(headers))
          raise(CLI::Kit::Abort, "Cannot access GitHub: #{resp.code}\n#{resp.body}") unless resp.code.to_i < 400
          resp
        end
      end

      def post(url, data, headers = {})
        start do |http|
          resp = http.post(url, data, default_headers.merge(headers))
          raise(CLI::Kit::Abort, "Cannot access GitHub: #{resp.code}\n#{resp.body}") unless resp.code.to_i < 400
          resp
        end
      end

      def default_headers
        {
          'Authorization' => "token #{GithubNotifier::Config.get("server", "token")}",
        }
      end

      def cached_notifications?
        File.exist?(NOTIFICATIONS_CACHE)
      end

      def notifications
        get('/notifications').body
      end
    end
  end
end
