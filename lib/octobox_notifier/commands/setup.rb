require 'octobox_notifier'
require 'optparse'

module OctoboxNotifier
  module Commands
    class Setup < OctoboxNotifier::Command
      def call(args, _name)
        options = parse_args(args)
        unless options.key?(:host)
          puts options.key?(:host).inspect
          options[:host] = CLI::UI::Prompt.ask("What host would you like to use?", default: "octobox.io")
        end
        unless options.key?(:token)
          options[:token] = CLI::UI::Prompt.ask("What is your octobox token? (Found at https://#{options[:host]}/settings)")
        end
        unless options.key?(:notify)
          options[:notify] = CLI::UI::Prompt.ask("Would you like to get system notifications?", options: ["Yes", "No"]) == "Yes"
        end
        OctoboxNotifier::Config.set("server", "host", options[:host])
        OctoboxNotifier::Config.set("server", "token", options[:token])
        OctoboxNotifier::Config.set("notification", "display", options[:notify])
      end

      def parse_args(args)
        options = {}
        OptionParser.new do |opts|
          opts.banner = "Usage: octobox_notifier setup [options]"

          opts.on("-h", "--host <HOST>", "The octobox host") do |host|
            options[:host] = host
          end

          opts.on("-t", "--token <TOKEN>", "Your octobox API token (found in settings)") do |token|
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
