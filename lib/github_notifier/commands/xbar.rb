require 'json'
require 'github_notifier'
require 'openssl'
require 'socket'

module GithubNotifier
  module Commands
    class Xbar < GithubNotifier::Command
      def call(args, _name)
        GithubNotifier::SystemNotification.show(notifications)
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
          JSON.parse(GithubNotifier::API.notifications).map { |data| GithubNotifier::Notification.new(data) }
        end
      end

      def output
        msg = [
          "#{notifications.size}| templateImage=#{Image.get('logo')}",
          "---",
          "View all in Github| templateImage=#{Image.get('inbox')} href=https://github.com/notifications/",
          "Refresh| templateImage=#{Image.get('refresh')} refresh=true",
          "---",
        ]

        msg.concat(
          notifications.flat_map do |notification|
            [
              "#{notification.menu_string} bash=#{OPEN} param2=#{notification.url} terminal=false refresh=true",
            ]
          end
        )

        msg.join("\n")
      end

    end
  end
end
