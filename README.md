# Capistrano::Mailgun  [![Build Status](https://travis-ci.org/spikegrobstein/capistrano-mailgun.png)](https://travis-ci.org/spikegrobstein/capistrano-mailgun)

*Bust a cap in your deployment notifications*

Mailgun.org is an excellent, API-driven email provider. So, bust out your nine, pop in the clip and send emails
easily from inside your Capistrano recipes.

`Capistrano::Mailgun` provides a simple interface for notifying of deploys, exposing your Capistrano
variables to your ERB template built on top of a more robust public interface to the Mailgun API.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-mailgun'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-mailgun

In your `Capfile`, add:

    require 'capistrano-mailgun'

## Quickstart

To send a notification after deploy, add the following to your `deploy.rb` file:

    set :mailgun_api_key, 'key-12345678901234567890123456789012' # your mailgun API key
    set :mailgun_domain, 'example.com' # your mailgun email domain
    set :mailgun_from, 'deployment@example.com' # who the email will appear to come from
    set :mailgun_recipients, [ 'you@example.com', 'otherguy@example.com' ] # who will receive the email

    # create an after deploy hook
    after :deploy, 'mailgun_notify'

That's it. When you do a deploy, it should automatically send an email using the built-in text and HTML
templates.

`Capistrano::Mailgun` defines a `mailgun_notify` task which calls the `mailgun.notify_of_deploy` function,
using your Capistrano configuration to send the notification.

## Example using mailgun.send_email

If you need a little more control over the message being sent or you want to bcc or be a little
more conditional over what you're sending, see the following example, which should be placed
in your `deploy.rb` file:

    # when using send_email, the following 2 settings are REQUIRED
    set :mailgun_api_key, 'key-12345678901234567890123456789012' # your mailgun API key
    set :mailgun_domain, 'example.com' # your mailgun email domain

    set :mailgun_recipient_domain, 'example.com' # append this to any unqualified email addresses

    set(:email_body) { abort "Please set email_body using `-s email_body='this is the body of the email'" }

    # some variables that we'll use when calling mailgun.send_email
    set :ops_emails, [ 'alice', 'bob' ]
    set :dev_emails, [ 'carl@contractors.com', 'dave' ]

    # some basic tasks
    namespace :email do
      task :ops do
        mailgun.send_email(
          :to => ops_emails, # build_recipients gets called automatically by Capistrano::Mailgun
          :from => 'some_dude@example.com',
          :subject => 'you have just been mailgunned',
          :text => email_body
        )
      end

      task :devs do
        mailgun.send_email(
          :to => 'no-reply@example.com',
          :from => 'no-reply@example.com',
          :bcc => mailgun.build_recipients(dev_emails, 'audit.example.com'), # note the different domain
          :subject => 'You guys are just developers',
          :text => email_body
        )
      end
    end

This defines 2 tasks that can be used to send emails to ops or devs. The `email:ops` task is using
an Capistrano variable `email_body` which should be set on the commandline. With this example, you could
send an email to ops guys like the following:

    cap email:ops -s email_body="You guys are awesome. Keep up the good work"

You could also take advantage of `:text_template` and/or `:html_template` for more complex messages. The
above is just an example.

Also, notice the use of `mailgun.build_recipients`. See documentation below for more information.

## Disabling Emails

If you want to prevent sending any email notifications for any reason, you can set the `mailgun_off`
Capistrano variable either via the `set` command or with the `-s` commandline options when calling
`cap`.

If using the Capistrano multistage plugin, you can put the following into one of your stage files
that you want to disable notifications for:

    set :mailgun_off, true

Or, when doing a normal deploy and you want to prevent notifications for this deploy, you can do the
following:

    cap deploy -s mailgun_off=1

Heads up: Setting `mailgun_off` to **anything** will disable emails. This includes setting it to `false`.

## Capistrano Variables

`Capistrano::Mailgun` leverages variables defined in Capistrano to reduce the amount of configuration
you need to do. The following are all variables it supports:

### mailgun_api_key (required)

Your API key. This MUST include the `key-` prefix.

### mailgun_domain (required)

The domain of your Mailgun account. This is used when calling the API and is required.

### mailgun_from (required for notify_of_deploy)

The email address that your notifications will appear to come from (by default).

### mailgun_recipients (required for notify_of_deploy)

The email address as a string or an array of email addresses who should recieve an email from `notify_of_deploy`.

You can optionally only specify just the part of the email address before the @ and `Capistrano::Mailgun` will
automatically append the `mailgun_recipient_domain` to it. See `mailgun_recipient_domain`.

If you omit the domain and don't specify `mailgun_recipient_domain`, a error will be raised.

### mailgun_cc

An array of email addresses who should be CC'd when `mailgun.notify_of_deploy` is called. This will
follow the same rules as the `mailgun_recipients` variable with respect to the handling of unqualified
email addresses.

### mailgun_bcc

An array of email addresses who should be BCC'd when `mailgun.notify_of_deploy` is called. This will
follow the same rules as the `mailgun_recipients` variable with respect to the handling of unqualified
eail addresses.

### mailgun_text_template (required for notify_of_deploy)

This is the path to the ERB template that `mailgun.notify_of_deploy` will use to create the text body of
your email. This is only required if you do not use the `mailgun_html_template` variable. You can
specify both text and html templates and the emails will contain the proper bodies where the client
supports it.

The default setting for this is `:deploy_text` which is a built-in template. See "Built-in Templates"
below for more information.

### mailgun_html_template (required for notify_of_deploy)

This is the path to the ERB template that will be used to generate the HTML body of the email. It is only
required if you do not specify the `mailgun_text_template` variable. You can specify both text and html
templates and emails will contain the proper bodies where the client supports it.

The default setting for this is `:deploy_html` which is a built-in template. See "Built-in Templates"
below for more information.

### mailgun_recipient_domain

The domain that will be automatically appended to incomplete email addresses in the `mailgun_recipients`.

Example:

    set :mailgun_recipient_domain, 'example.com'
    set :mailgun_recipients, [ 'alice', 'bob', 'carl@contractors.net' ]

When an email is sent from `Capistrano::Mailgun`, the recipients will be processed and the email will be sent to:

 * alice@example.com
 * bob@example.com
 * carl@contractors.net

If `mailgun_recipient_domain` is not set, `Capistrano::Mailgun` will raise an error.

### mailgun_subject

The subject to be used in deployment emails. This defaults to:

    [Deployment] #{ application.capitalize } deploy completed

In the event that you're using multistage, it will include that:

    [Deployment] #{ stage.capitalize } #{ application.capitalize } deploy completed

Setting this variable yourself will override the default.

### mailgun_message

An optional message can be specified to be included in the email. This is used inside the default templates,
so if you use your own templates, you'll have to include support for this variable yourself.

The purpose of this variable is to be set when calling capistrano so you can have a custom, per-deploy message.
You would call it in the following manner:

    cap deploy -s mailgun_message="Fixes that really nasty bug where our site does not work"

### mailgun_off

Setting `mailgun_off` to any value, either via the `-s` commandline switch or with `set` in your recipe
will completely disable any Mailgun notifications, regardless of whether they're sent with `mailgun.send_email`
or with the built-in `mailgun_notify` task.

See above `Disabling Emails` section for examples.

### github_url

If your project is hosted on Github and you'd like to have links to the Github repository in the deployment
notifications, set this. It should be in the following format:

    https://github.com/USERNAME/PROJECT

This is used for linking to commits from the log and linking to the Github page for the exact revision that
was deployed.

## Capistrano Tasks

### mailgun_notify

This task is defined strictly for convenience in defining Capistrano hooks and for sending a notification
from the commandline. All it does is run `mailgun.notify_of_deploy` on your local machine.

Normally, you'd want to have an after-hook on `deploy` defined as follows:

    after :deploy, 'mailgun_notify'

## Function API

`Capistrano::Mailgun` has a couple of functions to simplify some common tasks. The following are the functions:

### mailgun.build_recipients( recipients, default_domain=nil )

Given an array of email addresses, this will join them with a comma so any recipients field with more than 1 recipient
will be formatted properly, have the recipients list deduplicated and returned as a string. Typically, you will not call
this function directly as `Capistrano::Mailgun` calls it implicitely on your `to`, `cc` and `bcc` fields before hitting
the Mailgun API.

You can also pass an alternate `default_domain`. This is useful if you're not using the global `mailgun_recipient_domain`
Capistrano variable of if you want to override the behavior in a specific case. `mailgun.build_recipients` will always
choose the specified `default_domain` passed to the function over the Capistrano variable `mailgun_recipient_domain`.

### mailgun.notify_of_deploy

This is a convenience function to send an email via the Mailgun api using your Capistrano variables for declarative
configuration. It will use `mailgun_html_template` and `mailgun_text_template` to generate the email body when set,
`mailgun_recipients` for who to address the email to, `mailgun_from` for the reply-to field
of the email and `mailgun_subject` for the subject of the email.

See Quickstart, above, for an example.

### mailgun.send_email( options )

This is the base function for operating the Mailgun API. It uses the `mailgun_api_key` and `mailgun_domain`
Capistrano variables for interacting with the service. If you need additional control over headers and options
when sending the emails, call this function directly. For a full list of options, see the Mailgun REST API
documentation:

http://documentation.mailgun.net/api-sending.html

This function also takes the following additional options:

 * `:text_template` -- a path to an ERB template for the text body of the email.
 * `:html_template` -- a path to an ERB template for the HTML body of the email.

The templates will have access to all of your Capistrano variables and anything else that Capistrano can see
such as methods and Capistrano plugins (including `Capistrano::Mailgun`).

Of course, you can also pass `:text` and `:html` options for the exact text/html bodies of the sent emails as they
will be passed directly to the Mailgun API.

No validation is done from this function, so errors from Mailgun will percolate up to you.

### deployer_username

This is a default capistrano variable that is defined in the gem. It will use the `git config user.name` if `scm` is
configured as `:git` or use `whoami` if not. This is handy if you want to notify people of which user
actually did the deployment.

## Built-in Templates

`Capistrano::Mailgun` comes with built-in templates for use with `mailgun.notify_of_deploy`. There are both HTML and Text
templates which include information such as the sha1 and ref that has been deployed as well as logs of the last
commits. Use of the Capistrano variable `github_url` will enable links back to the repository and direct links
to the commits in the log.

These files live inside the gem in the `lib/templates` directory, so feel free to pull them out, copy into
your project and customize.

By default, `mailgun.notify_of_deploy` sets `mailgun_text_template` to `:default_text` and `mailgun_html_template`
to `:default_html`, which signals it to use these built-in templates. Overriding those variables with absolute
paths to your own templates will signal mailgun to use those. Setting either variable to `nil` will prevent
`mailgun.notify_of_deploy` from using anything for either the text or HTML portion of the email.

## Limitations

 * Only supports ERB for templates. This should be changed in a future release.
 * Currently requires that ERB templates are on the filesystem. Future releases may allow for inline templates.
 * Support for VCSs other than `:git` is lacking. `Capistrano::Mailgun` has been built with git and Github in mind.
   If anyone has interest in adding support for other another version control system, that would be great.
   Using this with a VCS other than Git may yeild unpredictable results.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Acknowledgements

`Capistrano::Mailgun` is written by Spike Grobstein and is used in production at [Ticket Evolution](http://www.ticketevolution.com)

`Capistrano::Mailgun` leverages the awesome email sending API of [Mailgun.org](http://mailgun.org). You should definitely check it out.

## License

`Capistrano::Mailgun` is &copy;2012 Spike Grobstein and licensed under the MIT License. See `LICENSE` file.
