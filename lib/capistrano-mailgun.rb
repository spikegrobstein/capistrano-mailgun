require "capistrano-mailgun/version"
require 'restclient'
require 'erb'


module Capistrano
  module Mailgun

    class Client
      attr_accessor :template, :subject, :recipients, :from_address

      def initialize(binding_context, template_path, subject, recipients, from_address)
        @template = load_template(template_path)
        @subject = subject
        @recipients = recipients
        @from_address = from_address
        @binding_context = binding_context
      end

      def load_template(template_path)
        @template = ERB.new( File.open(template_path, 'r').read )
      end

      def send!
        body = @template.run(@binding_context)
        puts body
      end
    end

    def send_notification(template)
      puts "can read name: #{ dude }"
      Client.new(self.binding, template, 'test', [ 'me@spike.cx' ], 'spike@ticketevolution.com').send!
    end

    def deployer_username
      `git config user.name`.chomp
    end
  end
end
