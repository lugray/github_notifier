require 'github_notifier'

module GithubNotifier
  module Commands
    Registry = CLI::Kit::CommandRegistry.new(
      default: 'xbar',
      contextual_resolver: nil
    )

    def self.register(const, cmd = nil, path = nil)
      cmd ||= const.to_s.downcase
      path ||= "github_notifier/commands/#{cmd}"
      autoload(const, path)
      Registry.add(->() { const_get(const) }, cmd)
    end

    register :Xbar
    register :Open
    register :Setup
  end
end
