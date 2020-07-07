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
        last_update = GithubNotifier::Config.get('notifications', 'last_update')
        headers = {}
        headers['If-Modified-Since'] = last_update if last_update && cached_notifications?
        resp = get('/notifications?all=true', headers)
        if resp.code.to_i == 304
          File.read(NOTIFICATIONS_CACHE)
        elsif resp.code.to_i == 200
          FileUtils.mkdir_p(File.dirname(NOTIFICATIONS_CACHE))
          File.write(NOTIFICATIONS_CACHE, resp.body.force_encoding('utf-8'))
          GithubNotifier::Config.set('notifications', 'last_update', resp['Last-Modified'])
          resp.body
        end
      end
    end
  end
end
