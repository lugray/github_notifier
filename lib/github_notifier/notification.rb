# frozen_string_literal: true

require 'github_notifier'

module GithubNotifier
  class Notification
    attr_reader :data

    OPEN   = 'open'
    MERGED = 'merged'
    CLOSED = 'closed'
    DRAFT  = 'draft'

    ISSUE        = 'Issue'
    PULL_REQUEST = 'PullRequest'
    COMMIT       = 'Commit'
    RELEASE      = 'Release'
    ALERT        = 'RepositoryVulnerabilityAlert'
    DISCUSSION   = 'Discussion'

    ICONS = {
      ISSUE        => 'issue',
      PULL_REQUEST => 'pr',
      COMMIT       => 'commit',
      RELEASE      => 'release',
      ALERT        => 'alert',
      DISCUSSION   => 'discussion',
    }.freeze

    MAX_TITLE_LENGTH = 30

    def initialize(data)
      @data = data
    end

    def id
      data.fetch('id').to_i
    end

    def title
      data.fetch('subject').fetch('title')
    end

    def open?
      state == OPEN
    end

    def pr?
      type == PULL_REQUEST
    end

    def type
      data.fetch('subject').fetch('type')
    end

    def short_type
      type.each_char.select { |c| c.upcase == c }.join
    end

    def reason
      data.fetch('reason')
    end

    def repo_name
      data.fetch('repository').fetch('name')
    end

    def elided_title
      if title.length > MAX_TITLE_LENGTH
        "#{title[0...MAX_TITLE_LENGTH-1]}…"
      else
        title
      end
    end

    def icon
      "templateImage=#{Image.get(ICONS.fetch(type))}"
    end

    def url
      data.fetch('subject').fetch('url')&.sub('api.github.com/repos', 'github.com')&.sub('/pulls/', '/pull/')
    end

    def menu_string
      "#{repo_name} #{elided_title.gsub('|','｜')} (#{reason})| #{icon}"
    end
  end
end
