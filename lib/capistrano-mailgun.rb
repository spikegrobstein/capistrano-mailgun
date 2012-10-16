require "capistrano-mailgun/version"
require 'restclient'
require 'erb'


module Capistrano
  module Mailgun

    # Load the base configuration into the given Capistrano::Instance.
    # This is primarily used for testing and is executed automatically when requiring
    # the library in a Capistrano recipe.
    def self.load_into(config)
      config.load do

        Capistrano.plugin :mailgun, Capistrano::Mailgun

        set(:mailgun_subject) { "[Deployment] #{ application.capitalize } completed" }

        set(:mailgun_api_key)           { abort "Please set mailgun_api_key accordingly" }
        set(:mailgun_domain)            { abort "Please set mailgun_domain accordingly" }
        set(:mailgun_from)              { abort "Please set mailgun_from to your desired From field" }
        set(:mailgun_recipients)        { abort "Please specify mailgun_recipients" }
        set(:mailgun_recipient_domain)  { abort "Please set mailgun_recipient_domain accordingly" }

        set(:deployer_username) do
          if fetch(:scm, nil).to_sym == :git
            `git config user.name`.chomp
          else
            `whoami`.chomp
          end
        end


      end # config.load
    end

    # Simple wrapper for sending an email with a given template
    # Supports all options that the Mailgun API supports. In addition, it also accepts:
    # * +:text_template+ -- the path to the template for the text body. It will be processed and interpolated and set the +text+ field when doing the API call.
    # * +:html_template+ -- the path to the template for the html body. It will be processed and interpolated and set the +html+ field when doing the API call.
    def send_email(options)
      options = process_send_email_options(options)

      RestClient.post build_mailgun_uri( mailgun_api_key, mailgun_domain ), options
    end

    # Sends the email via the Mailgun API using variables configured in Capistrano.
    # It depends on the following Capistrano vars in addition to the default:
    # * +mailgun_recipients+
    # * +mailgun_from+
    # * +mailgun_subject+
    # Requires one or both of the following:
    # * +mailgun_text_template+
    # * +mailgun_html_template+
    #
    # See README for explanations of the above variables.
    def notify_of_deploy
      options = {
        :to => build_recipients( fetch(:mailgun_recipients) ),
        :from => fetch(:mailgun_from),
        :subject => fetch(:mailgun_subject)
      }

      if fetch(:mailgun_text_template, nil).nil? && fetch(:mailgun_html_template, nil).nil?
        abort "You must specify one (or both) of mailgun_text_template and mailgun_html_template to use notify_of_deploy"
      end

      options[:text_template] = fetch(:mailgun_text_template) if fetch(:mailgun_text_template, nil)
      options[:html_template] = fetch(:mailgun_html_template) if fetch(:mailgun_html_template, nil)

      send_email options
    end

    # Placeholder method for hunting down templates. Currently does nothing.
    def find_template(t)
      return t
      File.join( File.dirname(__FILE__), t )
    end

    # Given an array of +recipients+, it returns a comma-delimited, deduplicated string, suitable for populating the +to+ field of a Mailgun API call.
    # Optionally, it will take a +default_domain+ which will automatically be appended to any unqualified recipients (eg: 'spike' => 'spike@example.com')
    def build_recipients(recipients, default_domain=nil)
      [*recipients].map do |r|
        if r.match /.+?@.+?$/ # the email contains an @ so it's fully-qualified.
          r
        else
          "#{ r }@#{ default_domain || fetch(:mailgun_recipient_domain) }"
        end
      end.uniq
    end

    private

    # apply templates and all that jazz
    def process_send_email_options(options)
      text_template = options.delete(:text_template)
      html_template = options.delete(:html_template)

      options[:text] = ERB.new( File.open( find_template(text_template) ).read ).result(self.binding) if text_template
      options[:html] = ERB.new( File.open( find_template(html_template) ).read ).result(self.binding) if html_template

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
