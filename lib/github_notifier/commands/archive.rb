require 'github_notifier'

module GithubNotifier
  module Commands
    class Archive < GithubNotifier::Command
      def call(args, _name)
        ids = args.join(',').split(',').map { |id| "id[]=#{id}" }.join('&')
        GithubNotifier::API.post("/notifications/archive_selected.json", "#{ids}&value=true")
      end
    end
  end
end
