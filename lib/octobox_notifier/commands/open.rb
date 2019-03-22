require 'octobox_notifier'

module OctoboxNotifier
  module Commands
    class Open < OctoboxNotifier::Command
      def call(args, _name)
        id, *to_open = args

        CLI::Kit::System.system('open', *to_open)

        OctoboxNotifier::API.post("/notifications/mark_read_selected.json?id=#{id}", "")
      end
    end
  end
end
