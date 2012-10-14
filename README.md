# Capistrano-Mailgun

*Bust a cap in your deployment notifications*

Send emails with erb template bodies easily from inside your capistrano recipes.

Although built primarily for sending notification emails of deploys, it also includes nice helper methods
for sending any kind of email via the Mailgun API.

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

    require 'capistrano-mailgun'

    set :mailgun_api_key, 'key-12345678901234567890123456789012' # your mailgun API key
    set :mailgun_domain, 'example.com' # your mailgun email domain
    set :mailgun_from, 'deployment@example.com' # who the email will appear to come from
    set :mailgun_recipients, [ 'you@example.com', 'otherguy@example.com' ] # who will receive the email

    # The erb template will have visibility into all your capistrano variables.
    # this template will be the text body of the notification email
    set :mailgun_text_template, File.join(File.dirname(__FILE__), 'mail.erb')

    # create an after deploy hook
    after(:deploy) { mailgun.notify_of_deploy }

You should then create a `mail.erb` file in the same directory as `deploy.rb`:

    <%= application %> has just been deployed by <%= deployer_name %>, yay!

That's it. When you do a deploy, it should automatically send an email.

## Capistrano Variables

`capistrano-mailgun` leverages variables defined in Capistrano to reduce the amount of configuration
you need to do. The following are all variables it supports:

### mailgun_api_key (required)

Your API key. This MUST include the `key-` prefix.

### mailgun_domain (required)

The domain of your Mailgun account. This is used when calling the API and is required.

### mailgun_from (required for notify_of_deploy)

The email address that your notifications will appear to come from (by default).

### mailgun_recipients (required for notify_of_deploy)

An array of email addresses who should recieve a notification when a deployment completes.

You can optionally only specify just the part of the email address before the @ and `capistrano-mailgun` will
automatically append the `mailgun_recipient_domain` to it. See `mailgun_recipient_domain`.

### mailgun_text_template (required for notify_of_deploy)

This is the path to the ERB template that `Capistrano::Mailgun` will use to create the text body of
your email. This is only required if you do not use the `mailgun_html_template` variable. You can
specify both text and html templates and the emails will contain the proper bodies where the client
supports it.

### mailgun_html_template (required for notify_of_deploy)

This is the path to the ERB template that will be used to generate the HTML body of the email. It is only
required if you do not specify the `mailgun_text_template` variable. You can specify both text and html
templates and emails will contain the proper bodies where the client supports it.

### mailgun_recipient_domain

The domain that will be automatically appended to incomplete email addresses in the `mailgun_recipients`.

### mailgun_subject

The subject to be used in deployment emails. This defaults to:

    [Deployment] #{ application.capitalize } complete

Setting this will override the default.

## Function API

`capistrano-mailgun` has a couple of methods to enable you to send emails easily. The following are the functions:

### mailgun.notify_of_deploy

This is a convenience function to send an email via the Mailgun api using your Capistrano variables for
basic configuration. It will use either/or `mailgun_html_template` and `mailgun_text_template` to generate the
email body, `mailgun_recipients` for who to address the email to, `mailgun_from` for the reply-to field
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

The templates will have access to all of your Capistrano variables.

Of course, you can also pass `:text` and `:html` options for the exact text/html bodies of the sent emails.

### deployer_username

This is a default capistrano variable that is defined in the gyem. It will use the `git config user.name` if `scm` is
configured as `:git` or use `whoami` if not. This is handy if you want to notify people of which user
actually did the deployment.

## Limitations

 * Only supports ERB for templates. This should be changed in a future release.
 * Currently requires that ERB templates are on the filesystem. Future releases may allow for inline templates.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
