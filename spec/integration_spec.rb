require 'spec_helper'

describe "Integration testing for Capistrano::Mailgun" do

  let(:config) do
    Capistrano::Configuration.new
  end

  before do
    Capistrano::Mailgun.load_into(config)

    RestClient.stub(:post)
  end

  let(:mailgun) { config.mailgun }

  context "when overriding defaults" do

    before do
      config.stub!(:run_locally => 'local output')

      config.load do
        set :application, 'testing'
        set :scm, :git

        # deploy stuff stubbing
        set :latest_revision, 'asdfasdf'
        set :real_revision, 'asdfasdf'

        # base Capistrano::Mailgun config
        set :mailgun_api_key, 'api-dummy-key'
        set :mailgun_domain, 'example.com'
      end
    end

    context "when using mailgun.notify_of_deploy" do
      before do
        config.load do
          set :mailgun_from, 'noreply@example.com'
          set :mailgun_recipients, 'everyone@example.com'
        end
      end

      after do
        mailgun.notify_of_deploy
      end


      it "should allow user to unset text template" do
        config.load do
          set :mailgun_text_template, nil
        end

        RestClient.should_receive(:post) do |url, opts|
          opts.has_key?(:text).should be_false
          opts.has_key?(:html).should be_true
        end
      end

      it "should allow user to unset html template" do
        config.load do
          set :mailgun_html_template, nil
        end

        RestClient.should_receive(:post) do |url, opts|
          opts.has_key?(:text).should be_true
          opts.has_key?(:html).should be_false
        end
      end

      context "email subject" do

        it "should include the stage if that's defined" do
          config.load do
            set :stage, 'production'
          end

          RestClient.should_receive(:post) do |url, opts|
            opts[:subject].should match(/\bproduction\b/i)
          end
        end

        it "should allow overriding of subject" do
          config.load do
            set :mailgun_subject, 'Test subject'
          end

          RestClient.should_receive(:post) do |url, opts|
            opts[:subject].should == 'Test subject'
          end
        end
      end

      it "should use mailgun_from for :from field" do
        RestClient.should_receive(:post) do |url, opts|
          opts[:from].should == 'noreply@example.com'
        end
      end

      it "should use mailgun_recipients for :to field" do
        RestClient.should_receive(:post) do |url, opts|
          opts[:to].should == 'everyone@example.com'
        end
      end

      context "when using mailgun_cc" do
        it "should use CC field if it's set" do
          config.load do
            set :mailgun_cc, 'cc@example.com'
          end

          RestClient.should_receive(:post) do |url, opts|
            opts[:cc].should == 'cc@example.com'
          end
        end

        it "should not use CC field if it's not set" do
          RestClient.should_receive(:post) do |url, opts|
            opts.has_key?(:cc).should be_false
          end
        end
      end

      context "when using mailgun_bcc" do
        it "should use bcc field if it's set" do
          config.load do
            set :mailgun_bcc, 'bcc@example.com'
          end

          RestClient.should_receive(:post) do |url, opts|
            opts[:bcc].should == 'bcc@example.com'
          end
        end

        it "should not use bcc field if it's not set" do
          RestClient.should_receive(:post) do |url, opts|
            opts.has_key?(:bcc).should be_false
          end
        end
      end

      context "when using mailgun_message" do
        it "should include a mailgun_message if set" do
          config.load do
            set :mailgun_message, '_custom_message_'
          end

          RestClient.should_receive(:post) do |url, opts|
            opts[:text].should include('_custom_message_')
            opts[:html].should include('_custom_message_')
          end
        end

        it "should not have the custom_message div if no custom_message is set" do
          RestClient.should_receive(:post) do |url, opts|
            opts[:html].should_not include('id="mailgun_message"')
          end
        end
      end

    end

  end

end
