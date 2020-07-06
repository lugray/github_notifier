require 'json'
require 'github_notifier'
require 'openssl'
require 'socket'

module GithubNotifier
  module Commands
    class Bitbar < GithubNotifier::Command
      def call(args, _name)
        GithubNotifier::SystemNotification.show(notifications)
        GithubNotifier::KeyboardNotification.show(notifications)
        puts output
      rescue SocketError
        puts "| image=#{Image.get('logo', Image::RED)}"
        puts "---"
        puts "Network not available"
        puts "Refresh| templateImage=#{Image.get('refresh')} refresh=true"
      rescue
        puts "| image=#{Image.get('logo', Image::RED)}"
        puts "---"
        puts "An error occured"
        puts "Refresh| templateImage=#{Image.get('refresh')} refresh=true"
        raise
      end

      private

      def notifications
        @notifications ||= begin
          resp = CLI::Kit::Util.begin do
            GithubNotifier::API.get( "/notifications.json?per_page=100")
          end.retry_after(OpenSSL::SSL::SSLError, retries: 3)
          JSON.parse(resp.body).fetch('notifications').map { |data| GithubNotifier::Notification.new(data) }
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
          "#{unread_notifications.size}/#{notifications.size}| templateImage=#{Image.get('logo')}",
          "---",
          "View all in Github| templateImage=#{Image.get('inbox')} href=https://#{GithubNotifier::Config.get('server', 'host')}/",
          "Refresh| templateImage=#{Image.get('refresh')} refresh=true",
          "---",
        ]

        msg.concat(
          unread_notifications.flat_map do |notification|
            [
              "#{notification.menu_string} bash=#{MARK_READ_AND_OPEN} param2=#{notification.id} param3=#{notification.url} terminal=false refresh=true",
              "--Archive| templateImage=#{Image.get('archive')} bash=#{ARCHIVE} param2=#{notification.id} terminal=false refresh=true",
            ]
          end
        )

        if read_notifications.any?
          msg.concat([
            "---",
            "Archive all read notifications| templateImage=#{Image.get('archive')} bash=#{ARCHIVE} param2=#{read_notifications.map(&:id).join(',')} terminal=false refresh=true",
          ])
          msg.concat(
            read_notifications.flat_map do |notification|
              [
                "#{notification.menu_string} href=#{notification.url}",
                "--Archive| templateImage=#{Image.get('archive')} bash=#{ARCHIVE} param2=#{notification.id} terminal=false refresh=true",
              ]
            end
          )
        end
        msg.join("\n")
      end

    end
  end
end
