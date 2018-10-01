require 'octobox_notifier'

module OctoboxNotifier
  module Commands
    class Archive < OctoboxNotifier::Command
      def call(args, _name)
        ids = args.join(',').split(',').map { |id| "id[]=#{id}" }.join('&')
        OctoboxNotifier::API.post( "/notifications/archive_selected.json", "#{ids}&value=true")
      end
    end
  end
end
