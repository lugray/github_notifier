require 'octobox_notifier'

module OctoboxNotifier
  module Commands
    class Open < OctoboxNotifier::Command
      def call(args, _name)
        id, *to_open = args

        CLI::Kit::System.system('open', *to_open)

        OctoboxNotifier::API.post("/notifications/#{id}/mark_read.json", "")
      end
    end
  end
end
