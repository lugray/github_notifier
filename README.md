# Octobox Notifier

Use [bitbar](https://github.com/matryer/bitbar) to provide notifications.

## Requirements
1. An [octobox](https://github.com/octobox/octobox) account with `FETCH_SUBJECT` enabled.
2. [bitbar](https://github.com/matryer/bitbar)

## Installation
1. Clone this repo, then create a symlink in your bitbar directory to `octobox_bitbar.rb`
2. Copy your Octobox API token from the settings page
3. Run `security add-generic-password -a octobox-notifier -s ocotobox-token -w <YOUR_TOKEN> login`
4. (Optional) Install the `terminal_notifier` gem if you'd like to get notifications as well as the menubar content
