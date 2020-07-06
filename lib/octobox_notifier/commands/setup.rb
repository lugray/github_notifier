require 'octobox_notifier'
require 'optparse'

module OctoboxNotifier
  module Commands
    class Setup < OctoboxNotifier::Command
      def call(args, _name)
        options = parse_args(args)
        unless options.key?(:token)
          options[:token] = CLI::UI::Prompt.ask("What is your GitHub API token? (Create at https://github.com/settings/tokens/new?scopes=notifications&description=notifier)")
        end
        unless options.key?(:notify)
          options[:notify] = CLI::UI::Prompt.ask("Would you like to get system notifications?", options: ["Yes", "No"]) == "Yes"
        end
        OctoboxNotifier::Config.set("server", "token", options[:token])
        OctoboxNotifier::Config.set("notification", "display", options[:notify])
      end

      def parse_args(args)
        options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: octobox_notifier setup [options]"

          opts.on("-t", "--token <TOKEN>", "Your GitHub API token (Create at https://github.com/settings/tokens/new?scopes=notifications&description=notifier)") do |token|
            options[:token] = token
          end

          opts.on("-n", "--[no-]notify", "Enable system notifications") do |notify|
            options[:notify] = notify
          end
        end.parse!(args)
        options
      rescue OptionParser::MissingArgument
        parse_args(['--help'])
      end
    end
  end
end
