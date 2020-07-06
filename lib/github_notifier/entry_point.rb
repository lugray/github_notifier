require 'github_notifier'

module GithubNotifier
  module EntryPoint
    def self.call(args)
      cmd, command_name, args = GithubNotifier::Resolver.call(args)
      GithubNotifier::Executor.call(cmd, command_name, args)
    end
  end
end
