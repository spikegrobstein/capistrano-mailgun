require "capistrano-mailgun/version"
require 'restclient'
require 'erb'


module Capistrano
  module Mailgun

    # simple wrapper for sending an email with a given template
    def send_email(options)
      options = process_send_email_options(options)

      RestClient.post build_mailgun_uri( mailgun_api_key, mailgun_domain ), options
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

    private

    # regenerates the recipients list using hte mailgun_domain for any reciients without domains
    def build_recipients(recipients)
      [*recipients].map do |r|
        if r.match /.+?@.+?$/
          r
        else
          "#{ r }@#{ mailgun_recipient_domain }"
        end
      end.uniq
    end

    # apply templates and all that jazz
    def process_send_email_options(options)
      text_template = options.delete(:text_template)
      html_template = options.delete(:html_template)

      options[:text] = ERB.new( File.open( find_template(text_template) ) ).result(self.binding) if text_template
      options[:html] = ERB.new( File.open( find_template(html_template) ) ).result(self.binding) if html_template

      options
    end

    def build_mailgun_uri(mailgun_api_key, mailgun_domain)
      "https://api:#{ mailgun_api_key }@api.mailgun.net/v2/#{ mailgun_domain }/messages"
    end

  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.load do
    Capistrano.plugin :mailgun, Capistrano::Mailgun

    set(:mailgun_subject) { "[Deployment] #{ application.capitalize } completed" }

    set(:mailgun_api_key) { abort "Please set mailgun_api_key accordingly" }
    set(:mailgun_domain) { abort "Please set mailgun_domain accordingly" }
    set(:mailgun_from) { abort "Please set mailgun_from to your desired From field" }
    set(:mailgun_recipients) { abort "Please specify mailgun_recipients" }
    set(:mailgun_recipient_domain) { abort "Please set mailgun_recipient_domain accordingly" }

    set(:deployer_username) do
      if fetch(:scm, nil).to_sym == :git
        `git config user.name`.chomp
      else
        `whoami`.chomp
      end
    end

  end

end
