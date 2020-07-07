require 'base64'
require 'cli/ui'
require 'cli/kit'

CLI::UI::StdoutRouter.enable

module GithubNotifier
  extend CLI::Kit::Autocall

  TOOL_NAME           = 'github_notifier'
  ROOT                = File.expand_path('../..', __FILE__)
  LOG_FILE            = '/tmp/github_notifier.log'
  CACHE_HOME          = File.expand_path(ENV.fetch('XDG_CACHE_HOME',  '~/.cache'))
  TOOL_CACHE_PATH     = File.join(CACHE_HOME, TOOL_NAME)
  NOTIFICATIONS_CACHE = File.join(TOOL_CACHE_PATH, 'notifications')

  EXECUTABLE = File.join(ROOT, 'exe/shadowenv_bitbar')
  OPEN = "'#{EXECUTABLE}' param1=open"

  autoload(:API,                  'github_notifier/api')
  autoload(:Commands,             'github_notifier/commands')
  autoload(:Each,                 'github_notifier/each')
  autoload(:EntryPoint,           'github_notifier/entry_point')
  autoload(:Image,                'github_notifier/image')
  autoload(:Notification,         'github_notifier/notification')
  autoload(:Setup,                'github_notifier/setup')
  autoload(:SystemNotification,   'github_notifier/system_notification')
  autoload(:KeyboardNotification, 'github_notifier/keyboard_notification')

  autocall(:Config) { CLI::Kit::Config.new(tool_name: GithubNotifier::TOOL_NAME) }
  autocall(:Command) { CLI::Kit::BaseCommand }

  autocall(:Executor) { CLI::Kit::Executor.new(log_file: LOG_FILE) }
  autocall(:Resolver) do
    CLI::Kit::Resolver.new(
      tool_name: TOOL_NAME,
      command_registry: GithubNotifier::Commands::Registry
    )
  end

  autocall(:ErrorHandler) do
    CLI::Kit::ErrorHandler.new(
      log_file: LOG_FILE,
      exception_reporter: nil
    )
  end
end
