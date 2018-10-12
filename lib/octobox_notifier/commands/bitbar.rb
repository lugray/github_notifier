require 'json'
require 'octobox_notifier'
require 'openssl'

module OctoboxNotifier
  module Commands
    class Bitbar < OctoboxNotifier::Command
      def call(args, _name)
        OctoboxNotifier::SystemNotification.show(notifications)
        puts output
      end

      private

      def notifications
        @notifications ||= begin
          resp = CLI::Kit::Util.begin do
            OctoboxNotifier::API.get( "/notifications.json")
          end.retry_after(OpenSSL::SSL::SSLError, retries: 3)
          JSON.parse(resp.body).fetch('notifications').map { |data| OctoboxNotifier::Notification.new(data) }
        end
      end

      def unread_notifications
        notifications.select(&:unread?)
      end

      def read_notifications
        notifications.select(&:read?)
      end

      def output
        msg = [
          "#{unread_notifications.size}/#{notifications.size}| templateImage=#{IMAGE}",
          "---",
          "View all in Octobox| href=https://#{OctoboxNotifier::Config.get('server', 'host')}/",
          "Refresh| refresh=true",
          "---",
        ]

        msg.concat(
          unread_notifications.flat_map do |notification|
            [
              "#{notification.menu_string}| bash=#{MARK_READ_AND_OPEN} param2=#{notification.id} param3=#{notification.url} terminal=false refresh=true",
              "--Archive| bash=#{ARCHIVE} param2=#{notification.id} terminal=false refresh=true",
            ]
          end
        )

        if read_notifications.any?
          msg.concat([
            "---",
            "Archive all read notifications| bash=#{ARCHIVE} param2=#{read_notifications.map(&:id).join(',')} terminal=false refresh=true",
          ])
          msg.concat(
            read_notifications.flat_map do |notification|
              [
                "#{notification.menu_string}| href=#{notification.url}",
                "--Archive| bash=#{ARCHIVE} param2=#{notification.id} terminal=false refresh=true",
              ]
            end
          )
        end
        msg.join("\n")
      end

    end
  end
end
