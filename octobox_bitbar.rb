#!/usr/ruby

IMAGE = "iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAQAAADZc7J/AAAAAmJLR0QA/4ePzL8AAAAJcEhZcwAAFiUAABYlAUlSJPAAAAAHdElNRQfiAhcSADAZLWvdAAADJ0lEQVRIx53VbWiWZRQH8N993ZvuxaXk03oxCC1IYmUQFCWNMpoibrXsS0Fo0LfSJZK9fMkPRrCCyE+R0IogejHrS30IC0RaZi82goVJGi6j2qbW5l6e7dnTh/t+7t17IUfn4oHrOfc5/+ucc53/uWLT0uo1NxrVl2lqbHO7Y0qZZq3tnjOit6KIcgDvuxqRki1+VWWFfWpR9JjTpqzUJVYWOWfjfAA9RtNd2ZBLxNnJsZJ/NGTWVW6rfKvKAcQCyiIsQ1nIAEOqSSCCMB/AKVdaiETOm2AuQDE78WIAI/mwK/Kw+xEtaC31l59mF7Fbfe6Mskg53c0Xw5SbpeVI5E6NYrFYyP3yuzi3C+rdk4+g1W61ab1rfOErQ+oUFDRgyKABFzS4w93GUp9Re3yUAKzzRtYBYx71w38UcI2u9CgW2epwQItxQRBU2566H9RjWea23I8OqUaPp9Sk1pMeSmpQlSqC8w6DV61U5+UMYLcaKzwPPndSLAhi1QlAlJanyqHU4XoErRnAekGkKbuvkBY3JABBJKT3m8iUSDTdbcZFIpPpv6WZfXaNwZRYZL128KVFYvsygHcFVY6ArR4QxMpJBEnGfe7VZkCfP33qKuz0gurcXNhjJ67xmT/0GXSfTfq8mXze64wNWOJD/X7zt455WBHbZcgZA/arR5vfvVUpYmI+bLMOsRHPOGHVDPfr/GKHYTzuQRdS1oRpgAon3tHkmMWWOOJASrXIAd1q1eixxnsZH4JoLgCDNuowIdLspEdscVqzSMk2GwzkogqiZB5EMwYbvG2/g1artxclkZ/dpTiLkbk+iOdA1GpMGyxZhYwB5k9hpjzrhEaL9WvX7pxFLnfK07OsssRfN2RTpl7lqDHDzurMdC86a9i4b12b6TYb8kElgukqPOm4G0zqUbArF9Flek1YrdcTWQrR7BQKvteppKjFWlMzwi25VYsxZa/4zvKUgtF0EUs69GsyodOluucdJt0KXjLhJgN25LnQpWjSpDHfqLvoUK/1tTGTSoo+TvqglHHyCscX9C6E9LVKCb9O+X+u5spUvkXbAl+laZnyiaP8C2RC6xkl3ixRAAAAAElFTkSuQmCC"

require 'net/http'
require 'json'
require 'open3'

TMP_DATA_FILE = '/tmp/octobox-bitbar-ids.json'.freeze

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

def fail(msg)
  puts "💥#{msg}|#{IMAGE}"
  exit 1
end

def pluralize(n, str)
  "#{n} #{str}#{'s' unless n == 1}"
end

token, _, t = Open3.capture3('security', 'find-generic-password', '-w', '-l', 'octobox-token')
fail 'Cannot retrieve token' unless t.success?

data = Net::HTTP.start('octobox.shopify.io', 443, use_ssl: true) do |http|
  resp = http.get('/notifications.json', 'Authorization' => "Bearer #{token}")
  fail 'Cannot access octobox' unless resp.code.to_i == 200

  JSON.parse(resp.body)
end

current_ids = data.fetch('notifications')
  .select { |notification| notification.fetch('unread') }
  .map { |notification| notification.fetch('github_id') }
  .sort

notify_ids = nil
begin
  previous_ids = JSON.parse(File.read(TMP_DATA_FILE))
  notify_ids = current_ids - previous_ids
rescue Exception => _
  # ignore
end

File.write(TMP_DATA_FILE, JSON.generate(current_ids))

if current_ids.empty?
  TerminalNotifier.remove(:octobox)
elsif notify_ids.nil? || !notify_ids.empty?
  text = pluralize(current_ids.size, "unread item")
  text += ", " + pluralize(notify_ids.size, "new item") unless notify_ids.nil?

  TerminalNotifier.notify(
    text,
    title: 'Ocotobox',
    subtitle: 'Pending review',
    group: :octobox,
    execute: 'open https://octobox.shopify.io/',
    appIcon: "data:image/png;base64,#{IMAGE}",
  )
end

puts "#{current_ids.size}| image=#{IMAGE} href=https://octobox.shopify.io/"
