# frozen_string_literal: true

require 'octobox_notifier'

module OctoboxNotifier
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

    def unread_open_non_draft_pr?
      unread? && open? && pr? && !draft?
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

    def draft?
      data.fetch('subject').fetch('draft', false)
    end

    def icon
      case Each[type,         state,  draft?]
      when Each[ISSUE,        OPEN,   ANY   ] ; "image=#{Image.get('issue', Image::GREEN)}"
      when Each[ISSUE,        CLOSED, ANY   ] ; "image=#{Image.get('issue_closed', Image::RED)}"
      when Each[PULL_REQUEST, ANY,    true  ] ; "image=#{Image.get('pr', Image::GRAY)}"
      when Each[PULL_REQUEST, OPEN,   ANY   ] ; "image=#{Image.get('pr', Image::GREEN)}"
      when Each[PULL_REQUEST, CLOSED, ANY   ] ; "image=#{Image.get('pr', Image::RED)}"
      when Each[PULL_REQUEST, MERGED, ANY   ] ; "image=#{Image.get('pr', Image::PURPLE)}"
      when Each[PULL_REQUEST, ANY,    ANY   ] ; "image=#{Image.get('pr', Image::GREEN)}"
      when Each[COMMIT,       ANY,    ANY   ] ; "templateImage=#{Image.get('commit')}"
      when Each[RELEASE,      ANY,    ANY   ] ; "templateImage=#{Image.get('release')}"
      when Each[ALERT,        ANY,    ANY   ] ; "templateImage=#{Image.get('alert')}"
      else                                    ; raise "Unknown type, state, draft combo: #{type}, #{state}, #{draft?} for #{url}"
      end
    end

    def url
      data.fetch('web_url')
    end

    def menu_string
      "#{repo_name} #{title}| #{icon}"
    end
  end
end
