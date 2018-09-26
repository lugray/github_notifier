#!/usr/bin/ruby

require 'json'
require 'net/http'
require 'open3'
require 'openssl'

# Install terminal notifier gem if you want it.
begin
  require 'terminal-notifier'
rescue LoadError
  class TerminalNotifier
    def self.notify(*)
    end
    def self.remove(*)
    end
  end
end

class OctoboxNotification
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

class OctoboxBitbar
  IMAGE = "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"
  IMAGE_INVERTED = "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"
  TMP_DATA_FILE = '/tmp/octobox-bitbar-ids.json'.freeze
  MARK_READ_AND_OPEN = File.join(__dir__, 'octobox_mark_read_and_open.rb')
  ARCHIVE = File.join(__dir__, 'octobox_archive.rb')

  def terminal_image
    # Default logo is mostly black, so use inverted for "Dark" theme
    # Test on "Dark", so it gracefully supports where the AppleInterfaceStyle option doesn't exist
    %x{defaults read -g AppleInterfaceStyle}.chomp == "Dark" ? IMAGE_INVERTED : IMAGE
  end

  def set_notification
    if current_ids.empty?
      TerminalNotifier.remove(:octobox)
    elsif notification_changed && unread_notifications.size == 1
      notification = unread_notifications.first
      TerminalNotifier.notify(
        notification.title,
        title: "Octobox",
        subtitle: "New #{notification.type} in #{notification.repo_name}",
        group: :octobox,
        execute: "#{MARK_READ_AND_OPEN} '#{notification.id}' '#{notification.url}'",
        appIcon: "data:image/png;base64,#{terminal_image}",
      )
    elsif notification_changed
      TerminalNotifier.notify(
        pluralize(current_ids.size, "unread item"),
        title: 'Octobox',
        subtitle: 'Pending review',
        group: :octobox,
        execute: 'open https://octobox.shopify.io/',
        appIcon: "data:image/png;base64,#{terminal_image}",
      )
    end
  end

  def to_s
    msg = [
      "#{unread_notifications.size}/#{notifications.size}| templateImage=#{IMAGE}",
      "---",
      "View all in Octobox| href=https://octobox.shopify.io/",
      "Refresh| refresh=true",
      "---",
    ]

    msg.concat(
      unread_notifications.flat_map do |notification|
        [
          "#{notification.menu_string}| bash=#{MARK_READ_AND_OPEN} param1=#{notification.id} param2=#{notification.url} terminal=false refresh=true",
          "--Archive| bash=#{ARCHIVE} param1=#{notification.id} terminal=false refresh=true",
        ]
      end
    )

    if read_notifications.any?
      msg.concat([
        "---",
        "Archive all read notifications| bash=#{ARCHIVE} param1=#{read_notifications.map(&:id).join(',')} terminal=false refresh=true",
      ])
      msg.concat(
        read_notifications.flat_map do |notification|
          [
            "#{notification.menu_string}| href=#{notification.url}",
            "--Archive| bash=#{ARCHIVE} param1=#{notification.id} terminal=false refresh=true",
          ]
        end
      )
    end
    msg.join("\n")
  end

  private

  def pluralize(n, str)
    "#{n} #{str}#{'s' unless n == 1}"
  end

  def token
    return @token if defined?(@token)
    @token, _, t = Open3.capture3('security', 'find-generic-password', '-w', '-l', 'octobox-token')
    raise 'Cannot retrieve token' unless t.success?
    @token
  end

  def notifications
    begin_for_retry do
      @notifications ||= Net::HTTP.start('octobox.shopify.io', 443, use_ssl: true) do |http|
        resp = http.get('/notifications.json', 'Authorization' => "Bearer #{token}")
        raise 'Cannot access octobox' unless resp.code.to_i == 200

        JSON.parse(resp.body).fetch('notifications').map { |data| OctoboxNotification.new(data) }
      end
    end.retry_after(OpenSSL::SSL::SSLError, retries: 3)
  end

  def unread_notifications
    notifications.select(&:unread?)
  end

  def read_notifications
    notifications.select(&:read?)
  end

  def current_ids
    unread_notifications.map(&:gh_id).sort
  end

  def previous_ids
    return @previous_ids if defined?(@previous_ids)
    @previous_ids = begin
      JSON.parse(File.read(TMP_DATA_FILE))
    rescue Exception => _
      []
    end
    File.write(TMP_DATA_FILE, JSON.generate(current_ids))
    @previous_ids
  end

  def notification_changed
    current_ids != previous_ids
  end

  def begin_for_retry(&block_that_might_raise)
    Retrier.new(block_that_might_raise)
  end

  class Retrier
    def initialize(block_that_might_raise)
      @block_that_might_raise = block_that_might_raise
    end

    def retry_after(exception = StandardError, retries: 1, &before_retry)
      @block_that_might_raise.call
    rescue exception => e
      raise if (retries -= 1) < 0
      if before_retry
        if before_retry.arity == 0
          yield
        else
          yield e
        end
      end
      retry
    end
  end

  private_constant :Retrier
end

begin
  puts OctoboxBitbar.new.tap(&:set_notification)
rescue StandardError => e
  puts "💥 #{e.message}| templateImage=#{OctoboxBitbar::IMAGE}"
  puts "---"
  puts "#{e.class}: #{e.message}"
  puts e.backtrace
end
