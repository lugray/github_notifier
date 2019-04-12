# frozen_string_literal: true

require 'octobox_notifier'

module OctoboxNotifier
  class Notification
    attr_reader :data

    OPEN   = 'open'
    MERGED = 'merged'
    CLOSED = 'closed'

    ISSUE                          = 'Issue'
    PULL_REQUEST                   = 'PullRequest'
    COMMIT                         = 'Commit'
    RELEASE                        = 'Release'
    REPOSITORY_VULNERABILITY_ALERT = 'RepositoryVulnerabilityAlert'

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

    def open?
      state == OPEN
    end

    def pr?
      type == PULL_REQUEST
    end

    def unread_open_pr?
      unread? && open? && pr?
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
      when ISSUE
        "!\u20DD"
      when PULL_REQUEST
        '⭠ '
      when COMMIT
        '⏀'
      when RELEASE
        '🏷'
      when REPOSITORY_VULNERABILITY_ALERT
        '⚠︎'
      else
        raise "Unkown type: #{type}"
      end
    end

    def color
      case state
      when OPEN
        "\x1b[1;32m"
      when MERGED
        "\x1b[1;35m"
      when CLOSED
        "\x1b[31m"
      when nil
        ''
      else
        raise "Unkown state: #{state}"
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
