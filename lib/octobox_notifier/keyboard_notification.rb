require 'serialport'
require 'timeout'

module OctoboxNotifier
  module KeyboardNotification
    class Focus
      ConnectionError = Class.new(StandardError)

      def initialize
        device = Dir.glob("/dev/cu.usbmodemCkbio*")[0]
        raise(ConnectionError, "Keyboard not connected") unless device
        @serial = SerialPort.new(device, 9600)
      end

      def command(*parts)
        @serial.write("#{parts.map(&:to_s).join(" ")}\n")
        response
      end

      def response
        lines = []
        Timeout.timeout(2) do
          until (line = @serial.readline.chomp) == "."
            lines << line
          end
        end
        lines
      rescue Timeout::Error
        nil
      end
    end

    class << self
      def show(notifications, always: false)
        focus = Focus.new
        return unless always || OctoboxNotifier::Config.get_bool("notification", "keyboard")
        focus.command('led.unset-all')
        n = notifications.select(&:unread_open_non_draft_pr?).size
        if n > 0
          focus.command('led.value', 50)
          if n < 6
            focus.command('led.setrc', 0, n, 255, 255, 255)
          elsif n < 10
            focus.command('led.setrc', 0, n + 4, 255, 255, 255)
          else
            focus.command('led.setrc', 3, 10, 255, 255, 255) # n
          end
        end
      rescue Focus::ConnectionError
        nil
      end
    end
  end
end
