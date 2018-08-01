#!/usr/ruby

IMAGE = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAQAAADZc7J/AAAAAmJLR0QA/4ePzL8AAAAJcEhZcwAAFiUAABYlAUlSJPAAAAAHdElNRQfiAhcSADAZLWvdAAADJ0lEQVRIx53VbWiWZRQH8N993ZvuxaXk03oxCC1IYmUQFCWNMpoibrXsS0Fo0LfSJZK9fMkPRrCCyE+R0IogejHrS30IC0RaZi82goVJGi6j2qbW5l6e7dnTh/t+7t17IUfn4oHrOfc5/+ucc53/uWLT0uo1NxrVl2lqbHO7Y0qZZq3tnjOit6KIcgDvuxqRki1+VWWFfWpR9JjTpqzUJVYWOWfjfAA9RtNd2ZBLxNnJsZJ/NGTWVW6rfKvKAcQCyiIsQ1nIAEOqSSCCMB/AKVdaiETOm2AuQDE78WIAI/mwK/Kw+xEtaC31l59mF7Fbfe6Mskg53c0Xw5SbpeVI5E6NYrFYyP3yuzi3C+rdk4+g1W61ab1rfOErQ+oUFDRgyKABFzS4w93GUp9Re3yUAKzzRtYBYx71w38UcI2u9CgW2epwQItxQRBU2566H9RjWea23I8OqUaPp9Sk1pMeSmpQlSqC8w6DV61U5+UMYLcaKzwPPndSLAhi1QlAlJanyqHU4XoErRnAekGkKbuvkBY3JABBJKT3m8iUSDTdbcZFIpPpv6WZfXaNwZRYZL128KVFYvsygHcFVY6ArR4QxMpJBEnGfe7VZkCfP33qKuz0gurcXNhjJ67xmT/0GXSfTfq8mXze64wNWOJD/X7zt455WBHbZcgZA/arR5vfvVUpYmI+bLMOsRHPOGHVDPfr/GKHYTzuQRdS1oRpgAon3tHkmMWWOOJASrXIAd1q1eixxnsZH4JoLgCDNuowIdLspEdscVqzSMk2GwzkogqiZB5EMwYbvG2/g1artxclkZ/dpTiLkbk+iOdA1GpMGyxZhYwB5k9hpjzrhEaL9WvX7pxFLnfK07OsssRfN2RTpl7lqDHDzurMdC86a9i4b12b6TYb8kElgukqPOm4G0zqUbArF9Flek1YrdcTWQrR7BQKvteppKjFWlMzwi25VYsxZa/4zvKUgtF0EUs69GsyodOluucdJt0KXjLhJgN25LnQpWjSpDHfqLvoUK/1tTGTSoo+TvqglHHyCscX9C6E9LVKCb9O+X+u5spUvkXbAl+laZnyiaP8C2RC6xkl3ixRAAAAAElFTkSuQmCC"

require 'json'
require 'net/http'
require 'open3'

TMP_DATA_FILE = '/tmp/octobox-bitbar-ids.json'.freeze
MARK_READ_AND_OPEN = File.join(__dir__, 'octobox_mark_read_and_open.rb')
ARCHIVE = File.join(__dir__, 'octobox_archive.rb')

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

  def url
    data.fetch('web_url')
  end

  def menu_string
    "#{repo_name} (#{short_type}) #{title}"
  end
end

def fail(msg)
  puts "💥#{msg}|#{IMAGE}"
  exit 1
end

def pluralize(n, str)
  "#{n} #{str}#{'s' unless n == 1}"
end

token, _, t = Open3.capture3('security', 'find-generic-password', '-w', '-l', 'octobox-token')
fail 'Cannot retrieve token' unless t.success?

notifications = Net::HTTP.start('octobox.shopify.io', 443, use_ssl: true) do |http|
  resp = http.get('/notifications.json', 'Authorization' => "Bearer #{token}")
  fail 'Cannot access octobox' unless resp.code.to_i == 200

  JSON.parse(resp.body).fetch('notifications').map { |data| OctoboxNotification.new(data) }
end

unread_notifications = notifications.select(&:unread?)
read_notifications = notifications.select(&:read?)

current_ids = unread_notifications.map(&:gh_id).sort

previous_ids = begin
  JSON.parse(File.read(TMP_DATA_FILE))
rescue Exception => _
  []
end
notification_changed = current_ids != previous_ids

File.write(TMP_DATA_FILE, JSON.generate(current_ids))

if current_ids.empty?
  TerminalNotifier.remove(:octobox)
elsif notification_changed && unread_notifications.size == 1
  notification = unread_notifications.first
  TerminalNotifier.notify(
    notification.title,
    title: "Octobox",
    subtitle: "New #{notification.type} in #{notification.repo_name}",
    group: :octobox,
    execute: "open '#{notification.url}'",
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

puts <<~EOF
#{unread_notifications.size}| image=#{IMAGE}
---
View all in Octobox| href=https://octobox.shopify.io/
---
EOF
unread_notifications.each do |notification|
  puts "#{notification.menu_string}| bash=#{MARK_READ_AND_OPEN} param1=#{notification.id} param2=#{notification.url} terminal=false"
  puts "--Archive| bash=#{ARCHIVE} param1=#{notification.id} terminal=false refresh=true"
end
if read_notifications.any?
  puts "---"
  puts "Read notifications (#{read_notifications.count})"
  read_notifications.each do |notification|
    puts "--#{notification.menu_string}| href=#{notification.url}"
    puts "----Archive| bash=#{ARCHIVE} param1=#{notification.id} terminal=false refresh=true"
  end
end
