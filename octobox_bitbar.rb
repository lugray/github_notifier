#!/usr/ruby

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
  IMAGE = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAA7AAAAOwBeShxvQAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAIZSURBVFiF7dVLiI5RGAfwn3GbkAbjMgyrmdw1U4pyCylKjFvZMFNKiSTFlEhWKAsWFoqSKGVhNcbOQqIsbBCzQIkwiymjXMJYPOdrpm/e9+sbZeX711m873ku/+ec5/8cKqiggv8dw/9BzEaswHvMxXd8yzOuKhFoPPbhJl6gC9exPMO2HsfQgDnp3168w3ScwfwhFGEjPqEvZ13CqAH2a1CDdWhJJCZiBKoxNu1vLid5C37iDR7hYw6JDszE0eTXjGuYIap/LI7/F17hPHYkIrmowQ1x9FNwBcdxKJEqJnEvVdeONizAsxzCfamYRaUIzMOyZNyGpvS9BKdygnbiMFait0TywuoS1zIIY/AA+zEbw9Jp9Aq11OBCTtAOdJeRvLC2ZxGYgCfYivV4jdWiswuoxtOcoJ/xFW9xJPlV42SG7ZksAvVCw3BOqGBakc0inMWPHBLfsaHIpynD7mJhc+AcaMVp1Cbms/ChKFin6JOTWRUIad4RV7JbyPJEhl13lvNBPMTSxLK5aL9RNNroROJuRmXlrk1ZBKZim2i4PVioX7OX0ZO+d+ElJomeGWryHtHwmVgrjg5uiaZajANCGbBTjFeo+wsS7XnJYRyei7uDyfofrFYhwyyfq/hdRvLbYjyXRK14xVr1T8I6bBGzIQ+rRANmTcweUfnIYqdSAQtkqoQky8V00cAN+CLelPtCuhVUUEEFg/AHVmDRjjEAUFMAAAAASUVORK5CYII="
  TMP_DATA_FILE = '/tmp/octobox-bitbar-ids.json'.freeze
  MARK_READ_AND_OPEN = File.join(__dir__, 'octobox_mark_read_and_open.rb')
  ARCHIVE = File.join(__dir__, 'octobox_archive.rb')

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
        appIcon: "data:image/png;base64,#{IMAGE}",
      )
    elsif notification_changed
      TerminalNotifier.notify(
        pluralize(current_ids.size, "unread item"),
        title: 'Octobox',
        subtitle: 'Pending review',
        group: :octobox,
        execute: 'open https://octobox.shopify.io/',
        appIcon: "data:image/png;base64,#{IMAGE}",
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
  puts "💥 #{e.message}| image=#{OctoboxBitbar::IMAGE}"
  puts "---"
  puts "#{e.class}: #{e.message}"
  puts e.backtrace
end
