require 'octobox_notifier'

module OctoboxNotifier
  module EntryPoint
    def self.call(args)
      cmd, command_name, args = OctoboxNotifier::Resolver.call(args)
      OctoboxNotifier::Executor.call(cmd, command_name, args)
    end
  end
end
