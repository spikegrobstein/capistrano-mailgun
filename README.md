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

    set :mailgun_api_key, 'key-12345678901234567890123456789012' # your mailgun API key
    set :mailgun_domain, 'example.com' # your mailgun email domain
    set :mailgun_from, 'deployment@example.com' # who the email will appear to come from
    set :mailgun_recipients, [ 'you@example.com', 'otherguy@example.com' ] # who will receive the email

    # create an after:deploy hook
    # pass it the path to an erb template.
    # The erb template will have visibility into all your capistrano variables.
    after(:deploy) { mailgun.notify_of_deploy File.join(File.dirname(__FILE__), 'mail.erb') }

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

### mailgun_recipient_domain

The domain that will be automatically appended to incomplete email addresses in the `mailgun_recipients`.

### mailgun_subject

The subject to be used in deployment emails. This defaults to:

    [Deployment] #{ application.capitalize } complete

Setting this will override the default.

## Function API

`capistrano-mailgun` has a couple of methods to enable you to send emails easily. The following are the functions:

### mailgun.notify_of_deploy(erb_path)

Given a path to an erb template file, it will send an email to recipients specified using the above
Capistrano variables.

See Quickstart, above, for an example.

### mailgun.send_email( template, subject, recipients, from_address )

Given a path to a template, subject, recipients and a from\_address, send an email via the Mailgun API.

This function exists for convenience if you want to change the default behavior or notify during other events
triggered by Capistrano. `mailgun.send_email` adheres to the same behavior for recipients (automatically adding
the domain to the email addresses) as the regular `mailgun.notify_of_deploy` function.

The template will also be executed in the context of the recipe and will have access to everything that
capistrano has access to.

### mailgun.deployer_username

This function is only available from within the template. It will use the `git config user.name` if `scm` is
configured as `:git` or use `whoami` if not. This is handy if you want to notify people of which user
actually did the deployment.

## Limitations

 * Only supports plain-text emails. This should be fixed in the next release.
 * Only supports ERB for templates. This should be changed in a future release.
 * Simpler support for specifying templates? Should not need to pass absolute path, hopefully.
 * Extremely limited access to Mailgun parameters. Eventually I'd like to add support for better customization of this.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
