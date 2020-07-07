require 'github_notifier'

module GithubNotifier
  module Commands
    class Open < GithubNotifier::Command
      def call(args, _name)
        CLI::Kit::System.system('open', *args)
      end
    end
  end
end
