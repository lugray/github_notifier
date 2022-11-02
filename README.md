# GitHub Notifier

Use [xbar](https://github.com/matryer/xbar) to provide notifications.

## Requirements
1. [xbar](https://github.com/matryer/xbar)
2. [shadowenv](https://github.com/Shopify/shadowenv/) or some other way to get xbar to run with a non-system ruby where you can `bundle install` the gems.

## Installation
1. Clone this repo, then create a symlink in your xbar directory to `exe/shadowenv_xbar`, or whatever else you want to use to set up the right ruby
2. Create a GitHub API token at https://github.com/settings/tokens/new?scopes=notifications&description=notifier
3. Run `exe/github_notifier setup`
