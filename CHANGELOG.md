## 2013-01-30 - v1.3.0
 * added option to include list of servers deployed to in email notification
 * fixed a bug where requiring `capistrano-mailgun` after you load `deploy.rb` would cause variables to be overwritten with defaults.
 * don't call `mailgun.log_output` twice in html template

## 2012-11-?? - v1.2.0
 * properly handle failures when running git-log

## 2012-10-22 - v1.1.0
 * default subject now includes stage
 * built-in templates
 * support for custom messages

## 2012-10-15 - v1.0.2
 * Minor release
 * documentation changes

## 2012-10-15 - v1.0.1
 * Minor release
 * documentation changes

## 2012-10-15 - v1.0.0
 * Version 1.0.0!
 * Proper definitions of dependencies
 * Proper documentation
 * Full support for Mailgun API options in `mailgun.send_email`
 * Deduplication of email addresses in `mailgun.build_recipients`
 * Support for custom domain in `mailgun.build_recipients`
 * Support for HTML and text templates in emails using `mailgun.notify_of_deploy`
 * Full rspec test suite

## 2012-10-11 - v0.1.1

 * Fixed a bug where it would blow up if you `require` the gem inside a non-Capistrano environment

## 2012-10-11 - v0.1.0

Initial Release
