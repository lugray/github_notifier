require 'terminal-notifier'

module GithubNotifier
  module SystemNotification
    class << self
      def show(notifications, always: false)
        @notifications = notifications
        return unless always || GithubNotifier::Config.get_bool("notification", "display")
        if notifications.empty?
          TerminalNotifier.remove(:github)
        elsif new_notifications? && notifications.size == 1
          notification = notifications.first
          TerminalNotifier.notify(
            notification.title,
            title: "GitHub",
            subtitle: "New #{notification.type} in #{notification.repo_name}",
            group: :github,
            execute: "'#{EXECUTABLE}' 'open' '#{notification.url}'",
            appIcon: "data:image/png;base64,#{image}",
          )
        elsif new_notifications?
          TerminalNotifier.notify(
            pluralize(notifications.size, "unread item"),
            title: 'GitHub',
            subtitle: 'Pending review',
            group: :github,
            execute: "open https://github.com/notifications",
            appIcon: "data:image/png;base64,#{image}",
          )
        end
      end

      private

      attr_reader :notifications

      def image
        out, _ = CLI::Kit::System.capture2('defaults', 'read', '-g', 'AppleInterfaceStyle')
        # Default logo is mostly black, so use inverted for "Dark" theme
        # Test on "Dark", so it gracefully supports where the AppleInterfaceStyle option doesn't exist
        Image.get('logo', out.chomp == 'Dark' ? Image::WHITE : nil)
      end

      def pluralize(n, str)
        "#{n} #{str}#{'s' unless n == 1}"
      end

      def new_notifications?
        (current_ids - previous_ids).any?
      end

      def current_ids
        notifications.map(&:id).sort
      end

      def previous_ids
        return @previous_ids if defined?(@previous_ids)
        ids_string = GithubNotifier::Config.get("notification", "previous_ids") || ""
        @previous_ids = ids_string.split(",").map(&:to_i)
        GithubNotifier::Config.set("notification", "previous_ids", current_ids.join(','))
        @previous_ids
      end
    end
  end
end
