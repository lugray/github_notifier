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

    def repo_name
      data.fetch('repository').fetch('name')
    end

    def state
      # data.fetch('subject').fetch('state')
      'Uknown'
    end

    def draft?
      # data.fetch('subject').fetch('draft', false)
      false
    end

    def icon
      case Each[type,         state,  draft?]
      when Each[ISSUE,        OPEN,   ANY   ] ; "image=#{Image.get('issue', Image::GREEN)}"
      when Each[ISSUE,        CLOSED, ANY   ] ; "image=#{Image.get('issue_closed', Image::RED)}"
      when Each[ISSUE,        ANY,    ANY   ] ; "image=#{Image.get('issue', Image::GRAY)}"
      when Each[PULL_REQUEST, ANY,    true  ] ; "image=#{Image.get('pr', Image::GRAY)}"
      when Each[PULL_REQUEST, OPEN,   ANY   ] ; "image=#{Image.get('pr', Image::GREEN)}"
      when Each[PULL_REQUEST, CLOSED, ANY   ] ; "image=#{Image.get('pr', Image::RED)}"
      when Each[PULL_REQUEST, MERGED, ANY   ] ; "image=#{Image.get('pr', Image::PURPLE)}"
      when Each[PULL_REQUEST, ANY,    ANY   ] ; "image=#{Image.get('pr', Image::GRAY)}"
      when Each[COMMIT,       ANY,    ANY   ] ; "templateImage=#{Image.get('commit')}"
      when Each[RELEASE,      ANY,    ANY   ] ; "templateImage=#{Image.get('release')}"
      when Each[ALERT,        ANY,    ANY   ] ; "templateImage=#{Image.get('alert')}"
      else                                    ; raise "Unknown type, state, draft combo: #{type}, #{state}, #{draft?}"
      end
    end

    def url
      data.fetch('subject').fetch('url').sub('api.github.com/repos', 'github.com').sub('/pulls/', '/pull/')
    end

    def menu_string
      "#{repo_name} #{title}| #{icon}"
    end
  end
end
