require 'octobox_notifier'

module OctoboxNotifier
  class Notification
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def id
      data.fetch('id')
    end

    def gh_id
      data.fetch('github_id')
    end

    def title
      data.fetch('subject').fetch('title')
    end

    def unread?
      data.fetch('unread')
    end

    def read?
      !unread?
    end

    def type
      data.fetch('subject').fetch('type')
    end

    def short_type
      type.each_char.select { |c| c.upcase == c }.join
    end

    def repo_name
      data.fetch('repo').fetch('name')
    end

    def state
      data.fetch('subject').fetch('state')
    end

    def icon
      case type
      when 'Issue'
        "!\u20DD"
      when 'PullRequest'
        '⭠ '
      when 'Commit'
        '⏀'
      when 'Release'
        '🏷'
      when 'RepositoryVulnerabilityAlert'
        '⚠︎'
      else
        raise "Unkown type: #{type}"
      end
    end

    def color
      case state
      when 'open'
        "\x1b[1;32m"
      when 'merged'
        "\x1b[1;35m"
      when 'closed'
        "\x1b[31m"
      else
        ''
      end
    end

    def color_icon
      "#{color}#{icon}\x1b[0m"
    end

    def url
      data.fetch('web_url')
    end

    def menu_string
      "#{color_icon} #{repo_name} #{title}"
    end
  end
end
