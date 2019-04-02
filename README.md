# Octobox Notifier

Use [bitbar](https://github.com/matryer/bitbar) to provide notifications.

## Requirements
1. An [octobox](https://github.com/octobox/octobox) account
2. [bitbar](https://github.com/matryer/bitbar)
3. [shadowenv](https://github.com/Shopify/shadowenv/) or some other way to get bitbar to run with a non-system ruby where you can `bundle install` the gems.

## Installation
1. Clone this repo, then create a symlink in your bitbar directory to `exe/shadowenv_bitbar`, or whatever else you want to use to set up the right ruby
2. Copy your Octobox API token from the settings page
3. Run `exe/octobox_notifier setup`
