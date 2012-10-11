require "capistrano-mailgun/version"
require 'restclient'
require 'erb'


module Capistrano
  module Mailgun

    # simple wrapper for sending an email with a given template
    def send_email(template, subject, recipients, from_address)
      RestClient.post "https://api:#{ mailgun_api_key }@api.mailgun.net/v2/#{ mailgun_domain }/messages",
        :from => from_address,
        :to => build_recipients( recipients ).join(','),
        :subject => subject,
        :text => ERB.new( File.open( find_template(template), 'r' ).read ).result(self.binding)
    end

    # does a deploy notification leveraging variables defined in capistrano.
    def notify_of_deploy(template_name)
      send_email( template_name, mailgun_subject, build_recipients( mailgun_recipients ), mailgun_from )
    end

    # kinda unused function for locating a provided template
    def find_template(t)
      return t
      File.join( File.dirname(__FILE__), t )
    end

    # who is the current deployer?
    def deployer_username
      if fetch(:scm, nil).to_sym == :git
        `git config user.name`.chomp
      else
        `whoami`.chomp
      end
    end
    private

    # regenerates the recipients list using hte mailgun_domain for any reciients without domains
    def build_recipients(recipients)
      recipients.map do |r|
        if r.match /.+?@.+?$/
          r
        else
          "#{ r }@#{ mailgun_recipient_domain }"
        end
      end
    end

  end
end

Capistrano::Configuration.instance.load do
  Capistrano.plugin :mailgun, Capistrano::Mailgun

  set(:mailgun_subject) { "[Deployment] #{ application.capitalize } completed" }

  set(:mailgun_api_key) { abort "Please set mailgun_api_key accordingly" }
  set(:mailgun_domain) { abort "Please set mailgun_domain accordingly" }
  set(:mailgun_from) { abort "Please set mailgun_from to your desired From field" }
  set(:mailgun_recipients) { abort "Please specify mailgun_recipients" }
  set(:mailgun_recipient_domain) { abort "Please set mailgun_recipient_domain accordingly" }
end
