require 'github_notifier'

module GithubNotifier
  module Commands
    class Open < GithubNotifier::Command
      def call(args, _name)
        id, *to_open = args

        CLI::Kit::System.system('open', *to_open)

        GithubNotifier::API.post("/notifications/mark_read_selected.json?id=#{id}", "")
      end
    end
  end
end
