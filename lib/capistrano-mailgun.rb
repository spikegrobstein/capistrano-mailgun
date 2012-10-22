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

        set(:mailgun_subject) do
          [ "[Deployment]", fetch(:stage, '').to_s.capitalize, fetch(:application, '').capitalize, 'deploy completed'].join(' ').gsub(/\s+/, ' ')
        end

        set(:mailgun_api_key)           { abort "Please set mailgun_api_key accordingly" }
        set(:mailgun_domain)            { abort "Please set mailgun_domain accordingly" }
        set(:mailgun_from)              { abort "Please set mailgun_from to your desired From field" }
        set(:mailgun_recipients)        { abort "Please specify mailgun_recipients" }
        set(:mailgun_recipient_domain)  { abort "Please set mailgun_recipient_domain accordingly" }

        # set these to nil to not use, or set to path to your custom template
        set :mailgun_text_template, :deploy_text
        set :mailgun_html_template, :deploy_html

        set(:deployer_username) do
          if fetch(:scm, '').to_sym == :git
            `git config user.name`.chomp
          else
            `whoami`.chomp
          end
        end

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
        :to => fetch(:mailgun_recipients),
        :from => fetch(:mailgun_from),
        :subject => fetch(:mailgun_subject)
      }

      options[:cc] = fetch(:mailgun_cc) if fetch(:mailgun_cc, nil)
      options[:bcc] = fetch(:mailgun_bcc) if fetch(:mailgun_bcc, nil)

      if fetch(:mailgun_text_template, nil).nil? && fetch(:mailgun_html_template, nil).nil?
        abort "You must specify one (or both) of mailgun_text_template and mailgun_html_template to use notify_of_deploy"
      end

      options[:text_template] = fetch(:mailgun_text_template, nil)
      options[:html_template] = fetch(:mailgun_html_template, nil)

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

    # git log between +first_ref+ to +last_ref+
    def log_output(first_ref, last_ref)
      return @log_output unless @log_output.nil?

      log_output = run_locally("git log --oneline #{ first_ref }..#{ last_ref }")

      @log_output = log_output = log_output.split("\n").map do |line|
        fields = line.split("\s", 2)
        [ fields[0], fields[1] ]
      end
    end

    private

    def default_deploy_text_template_path
      default_template_path 'default.txt.erb'
    end

    def default_deploy_html_template_path
      default_template_path 'default.html.erb'
    end

    def default_template_path(name)
      File.join( File.dirname(__FILE__), 'templates', name)
    end

    def find_template(t)
      case t
      when :deploy_text then default_deploy_text_template_path
      when :deploy_html then default_deploy_html_template_path
      else
        abort "Unknown template symbol: #{ t }" if t.is_a?(Symbol)
        abort "Template not found: #{ t }" unless File.exists?(t)
        t
      end
    end

    # apply templates and all that jazz
    def process_send_email_options(options)
      text_template = options.delete(:text_template)
      html_template = options.delete(:html_template)

      options[:to] = build_recipients(options[:to]) unless options[:to].nil?
      options[:cc] = build_recipients(options[:cc]) unless options[:cc].nil?
      options[:bcc] = build_recipients(options[:bcc]) unless options[:bcc].nil?

      options[:text] = ERB.new( File.open( find_template(text_template) ).read ).result(self.binding) if text_template
      options[:html] = ERB.new( File.open( find_template(html_template) ).read ).result(self.binding) if html_template

      # clean up the text template a little
      if options[:text]
        options[:text].gsub! /^ +/, ''
        options[:text].gsub! /\n{3,}/, "\n\n"
      end

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
