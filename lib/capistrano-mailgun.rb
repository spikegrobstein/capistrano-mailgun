require "capistrano-mailgun/version"
require 'restclient'

module Capistrano
  module Mailgun

    # Load the base configuration into the given Capistrano::Instance.
    # This is primarily used for testing and is executed automatically when requiring
    # the library in a Capistrano recipe.
    def self.load_into(config)
      config.load do
        require 'capnotify'

        Capistrano.plugin :mailgun, Capistrano::Mailgun

        def _cset(name, *args, &block)
          unless exists?(name)
            set(name, *args, &block)
          end
        end

        # disable the capnotify splash screen
        _cset :capnotify_hide_splash, true

        _cset(:mailgun_subject) do
          [ "[Deployment]", fetch(:stage, '').to_s.capitalize, fetch(:application, '').capitalize, 'deploy completed'].join(' ').gsub(/\s+/, ' ')
        end

        _cset(:mailgun_api_key)           { abort "Please set mailgun_api_key accordingly" }
        _cset(:mailgun_domain)            { abort "Please set mailgun_domain accordingly" }
        _cset(:mailgun_from)              { abort "Please set mailgun_from to your desired From field" }
        _cset(:mailgun_recipients)        { abort "Please specify mailgun_recipients" }
        _cset(:mailgun_recipient_domain)  { abort "Please set mailgun_recipient_domain accordingly" }

        # some internal variables that mailgun will use as the app runs
        # _cset(:mailgun_deploy_servers)    { find_servers_for_task( find_task('deploy:update_code') ) }

        # _cset :mailgun_include_servers, false

        # default mailgun email tasks
        desc <<-DESC
          Send a mailgun deployment notification.

          This is here for convenience so you can force a notification to
          be sent from the commandline and also to simplify configuring
          after-deploy hooks and even after-mailgun-notify hooks.
        DESC
        task :mailgun_notify do
          mailgun.notify_of_deploy
        end

        on(:load) do
          capnotify.components.unshift(Capnotify::Component.new(:mailgun_message) do |c|
            c.header = 'Mailgun Message'

            c.content = fetch(:mailgun_message, nil)
          end)
        end


      end # config.load
    end

    # Simple wrapper for sending an email with a given template
    # Supports all options that the Mailgun API supports. In addition, it also accepts:
    # * +:text_template+ -- the path to the template for the text body. It will be processed and interpolated and set the +text+ field when doing the API call.
    # * +:html_template+ -- the path to the template for the html body. It will be processed and interpolated and set the +html+ field when doing the API call.
    #
    # If +mailgun_off+ is set, this function will do absolutely nothing.
    def send_email(options)
      return if exists?(:mailgun_off)
      options = process_send_email_options(options)

      RestClient.post build_mailgun_uri( mailgun_api_key, mailgun_domain ), options
    end

    # Sends the email via the Mailgun API using variables configured in Capistrano.
    # It depends on the following Capistrano vars in addition to the default:
    # * +mailgun_recipients+
    # * +mailgun_from+
    # * +mailgun_subject+
    #
    # See README for explanations of the above variables.
    def notify_of_deploy
      options = {
        :to => fetch(:mailgun_recipients),
        :from => fetch(:mailgun_from),
        :subject => fetch(:mailgun_subject)
      }

      options[:cc] = fetch(:mailgun_cc) if fetch(:mailgun_cc, nil)
      options[:bcc] = fetch(:mailgun_bcc) if fetch(:mailgun_bcc, nil)

      send_email options
    end

    # Given an array of +recipients+, it returns a comma-delimited, deduplicated string, suitable for populating the +to+, +cc+, and +bcc+ fields of a Mailgun API call.
    # Optionally, it will take a +default_domain+ which will automatically be appended to any unqualified recipients (eg: 'spike' => 'spike@example.com')
    def build_recipients(recipients, default_domain=nil)
      [*recipients].map do |r|
        if r.match /.+?@.+?$/ # the email contains an @ so it's fully-qualified.
          r
        else
          "#{ r }@#{ default_domain || fetch(:mailgun_recipient_domain) }"
        end
      end.uniq.sort.join(',')
    end

    private

    # apply templates and all that jazz
    # TODO: technically, options should not be a blank hash. technically there should be at least a :to field
    def process_send_email_options(options={})
      options[:to] = build_recipients(options[:to]) unless options[:to].nil?
      options[:cc] = build_recipients(options[:cc]) unless options[:cc].nil?
      options[:bcc] = build_recipients(options[:bcc]) unless options[:bcc].nil?

      options[:text] = fetch(:capnotify_deployment_notification_text) if fetch(:capnotify_deployment_notification_text_template_path, nil)
      options[:html] = fetch(:capnotify_deployment_notification_html) if fetch(:capnotify_deployment_notification_html_template_path, nil)

      options
    end

    # builds the Mailgun API URI from the given options.
    def build_mailgun_uri(mailgun_api_key, mailgun_domain)
      "https://api:#{ mailgun_api_key }@api.mailgun.net/v2/#{ mailgun_domain }/messages"
    end

  end
end

if Capistrano::Configuration.instance
  Capistrano::Mailgun.load_into(Capistrano::Configuration.instance)
end
