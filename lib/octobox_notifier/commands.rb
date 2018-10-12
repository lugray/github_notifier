require 'octobox_notifier'

module OctoboxNotifier
  module Commands
    Registry = CLI::Kit::CommandRegistry.new(
      default: 'bitbar',
      contextual_resolver: nil
    )

    def self.register(const, cmd = nil, path = nil)
      cmd ||= const.to_s.downcase
      path ||= "octobox_notifier/commands/#{cmd}"
      autoload(const, path)
      Registry.add(->() { const_get(const) }, cmd)
    end

    register :Archive
    register :Bitbar
    register :Open
    register :Setup
  end
end
