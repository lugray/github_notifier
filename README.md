# GitHub Notifier

Use [bitbar](https://github.com/matryer/bitbar) to provide notifications.

## Requirements
1. [bitbar](https://github.com/matryer/bitbar)
2. [shadowenv](https://github.com/Shopify/shadowenv/) or some other way to get bitbar to run with a non-system ruby where you can `bundle install` the gems.

## Installation
1. Clone this repo, then create a symlink in your bitbar directory to `exe/shadowenv_bitbar`, or whatever else you want to use to set up the right ruby
2. Create a GitHub API token at https://github.com/settings/tokens/new?scopes=notifications&description=notifier
3. Run `exe/github_notifier setup`
