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

      it "should allow overriding of subject" do
        config.load do
          set :mailgun_subject, 'Test subject'
        end

        RestClient.should_receive(:post) do |url, opts|
          opts[:subject].should == 'Test subject'
        end
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

    end

  end

end
