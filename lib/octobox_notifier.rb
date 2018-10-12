require 'base64'
require 'cli/ui'
require 'cli/kit'

CLI::UI::StdoutRouter.enable

module OctoboxNotifier
  extend CLI::Kit::Autocall

  TOOL_NAME = 'octobox_notifier'
  ROOT      = File.expand_path('../..', __FILE__)
  LOG_FILE  = '/tmp/octobox_notifier.log'

  IMAGE = Base64.strict_encode64(File.read(File.join(ROOT, "images/logo_black.png")))
  IMAGE_INVERTED = Base64.strict_encode64(File.read(File.join(ROOT, "images/logo_white.png")))
  TMP_DATA_FILE = '/tmp/octobox-bitbar-ids.json'.freeze
  MARK_READ_AND_OPEN = "#{File.join(ROOT, 'exe/octobox_notifier')} param1=open"
  ARCHIVE =  "#{File.join(ROOT, 'exe/octobox_notifier')} param1=archive"

  autoload(:API, 'octobox_notifier/api')
  autoload(:Commands, 'octobox_notifier/commands')
  autoload(:EntryPoint, 'octobox_notifier/entry_point')
  autoload(:Notification, 'octobox_notifier/notification')
  autoload(:Setup, 'octobox_notifier/setup')
  autoload(:SystemNotification, 'octobox_notifier/system_notification')

  autocall(:Config) { CLI::Kit::Config.new(tool_name: OctoboxNotifier::TOOL_NAME) }
  autocall(:Command) { CLI::Kit::BaseCommand }

  autocall(:Executor) { CLI::Kit::Executor.new(log_file: LOG_FILE) }
  autocall(:Resolver) do
    CLI::Kit::Resolver.new(
      tool_name: TOOL_NAME,
      command_registry: OctoboxNotifier::Commands::Registry
    )
  end

  autocall(:ErrorHandler) do
    CLI::Kit::ErrorHandler.new(
      log_file: LOG_FILE,
      exception_reporter: nil
    )
  end
end
