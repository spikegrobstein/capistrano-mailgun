require 'spec_helper'

describe Capistrano::Mailgun do

  let(:config) do
    Capistrano::Configuration.new
  end

  before do
    Capistrano::Mailgun.load_into(config)

    config.load do
      set :application, 'testapp'
    end

    RestClient.stub(:post)
  end

  let(:mailgun) { config.mailgun }

  context '#buid_recipients' do
    let(:email_1) { 'spike@example.com' }
    let(:email_2) { 'bob@example.com' }

    def build_recipients(recipients, default_domain=nil)
      mailgun.send(:build_recipients, recipients, default_domain)
    end

    it "should accept a single recipient (not an array)" do
      build_recipients(email_1).should == email_1
    end

    it "should accept an array of recipeints" do
      build_recipients( [email_1, email_2] ).should == [email_1, email_2].sort.join(',')
    end

    it "should deduplicate emails in the recipients" do
      build_recipients( [email_1, email_2, email_1] ).should == [email_1, email_2].sort.join(',')
    end

    context "when working with unqualified email addresses" do
      before do
        config.load do
          set :mailgun_recipient_domain, 'another.com'
        end
      end

      it "should add the mailgun_recipient_domain to any unqualified email addresses" do
        build_recipients( %w( spike ) ).should == 'spike@another.com'
      end

      it "should accept a mix of qualified and unqualified email addresses" do
        build_recipients( [email_1, 'spike']).should == [email_1, 'spike@another.com'].sort.join(',')
      end

    end

    context "when working with custom default domains" do

      it "should not raise an error if mailgun_recipient_domain is not defined, but default_domain is" do
        lambda { build_recipients( ['spike'], 'example.com' ) }.should_not raise_error
      end

      it "should use the passed default_domain over the mailgun_recipient_domain if it's passed" do
        config.load { set :mailgun_recipient_domain, 'example.com' }
        build_recipients( ['spike'], 'awesome.com' ).should == 'spike@awesome.com'
      end
    end


  end

  context "when ensuring cap variables are defined" do

    def should_require(var)
      lambda do
        config.load { fetch var }
      end.should raise_error
    end

    it "should require mailgun_api_key" do
      should_require :mailgun_api_key
    end

    it "should require mailgun_domain" do
      should_require :mailgun_domain
    end

  end

  context "#send_email" do

    before do
      config.load do
        set :mailgun_api_key, 'asdfasdf'
        set :mailgun_domain, 'example.com'
      end
    end

    context "mailgun_off" do

      context "when it is set" do
        before do
          config.load do
            set :mailgun_off, true
          end

          mailgun.stub!(:proces_send_email_options => true)
        end

        it "should not send emails when mailgun_off is set" do
          RestClient.should_not_receive(:post)
          mailgun.send_email({})
        end

      end

      context "when it is not set" do
        before do
          mailgun.stub!(:process_send_email_options => true)
        end

        it "should send emails when mailgun_off is not set" do
          RestClient.should_receive(:post)
          mailgun.send_email({})
        end
      end

    end

  end

  context "#notify_of_deploy" do

    before do
      config.load do
        set :mailgun_recipients, 'people@example.com'
        set :mailgun_from, 'me@example.com'

        set :mailgun_subject, 'new subject'
      end
    end

    it "should raise an error if neither mailgun_text_template nor mailgun_html_template are defined" do
      lambda { mailgun.send(:notify_of_deploy) }.should raise_error
    end

    it "should not raise an error if mailgun_text_template is defined" do
      config.load { set :mailgun_text_template, 'template' }
      mailgun.should_receive(:send_email)

      lambda { mailgun.notify_of_deploy }.should_not raise_error
    end

    it "should not raise an error if mailgun_html_template is defined" do
      config.load { set :mailgun_html_template, 'template' }
      mailgun.should_receive(:send_email)

      lambda { mailgun.notify_of_deploy }.should_not raise_error
    end

    context "when using cc and bcc" do
      let(:cc_email) { 'cc_email@example.com' }
      let(:bcc_email) { 'bcc_email@example.com' }

      context "when cc and bcc are included" do
        before do

          ERB.stub!(:new => mock(:result => 'completed template'))

          config.load do
            set :application, 'some application'

            set :mailgun_api_key, 'asdfasdf'
            set :mailgun_domain, 'example.com'

            set :mailgun_cc, 'cc_email@example.com'
            set :mailgun_bcc, 'bcc_email@example.com'

            set :mailgun_recipient_domain, 'example.com'
          end
        end

        after do
          mailgun.notify_of_deploy
        end

        it "should recieve process_send_email_options with cc and bcc values" do
          mailgun.should_receive(:process_send_email_options) do |options|
            options[:cc].should_not be_nil
            options[:bcc].should_not be_nil
          end
        end

        it "should run build_recipients on cc and bcc" do
          mailgun.should_receive(:build_recipients).with('people@example.com')
          mailgun.should_receive(:build_recipients).with(cc_email)
          mailgun.should_receive(:build_recipients).with(bcc_email)
        end

        it "should set the options in send_email to include cc if it's there" do
          config.load do
            set :mailgun_cc, nil
          end

          mailgun.should_not_receive(:build_recipients).with(cc_email)
        end

        it "should set the options in send_email to include bcc if it's there" do
          config.load do
            set :mailgun_cc, nil
          end

          mailgun.should_not_receive(:build_recipients).with(cc_email)
        end

      end

    end

  end

  context "collecting deployment servers" do
    let(:server_hostnames) { config.fetch(:mailgun_deploy_servers).map(&:host) }

    before do
      config.load do
        load 'deploy'

        set :application, 'rspec-app'
        set :repository, 'foo'

        set :current_revision, nil
        set :latest_revision, ''
        set :release_name, ''
        set :real_revision, ''

        role :web, 'server-a'
        role :app, 'server-b'

        role :web, 'server-c', :no_release => true
      end
    end

    context "#mailgun_deploy_servers" do

      it "should find servers that are included in 'deploy'" do
        pending
        server_hostnames.count.should == 2
        server_hostnames.should include('server-a')
        server_hostnames.should include('server-b')
      end

      it "should not find servers that are not included in 'deploy'" do
        pending
        server_hostnames.should_not include('server-c')
      end
    end

    context "templates" do
      let(:result) { mailgun.send(:process_send_email_options, { :text_template => :deploy_text, :html_template => :deploy_html }) }

      before do
        require 'capistrano/recipes/deploy/scm/git'
        Capistrano::Deploy::SCM::Git.any_instance.stub(:query_revision => '')
        mailgun.stub!(:log_output => [])
      end

      context "when mailgun_include_servers is set to true" do
        before do
          config.load { set :mailgun_include_servers, true }
        end

        it "should include the servers in the text template" do
          pending
          result[:text].should match('server-a')
        end

        it "should include the servers in the html template" do
          pending
          result[:html].should match('server-a')
          result[:html].should match('mailgun_servers')
        end

      end

      context "when mailgun_include_servers is set to false" do
        before do
          config.load { set :mailgun_include_servers, false }
        end

        it "should not include the servers in the text template" do
          pending
          result[:text].should_not match('server-a')
        end

        it "should not include the servers in the html template" do
          pending
          result[:html].should_not match('server-a')
          result[:html].should_not match('mailgun_servers')
        end
      end

    end

  end

  context "#process_send_email_options" do
    let(:test_mailgun_domain) { 'example.com' }

    before do
      config.load { set :mailgun_domain, 'example.com' }
    end

    it "should not return :text field if capnotify_deployment_notification_text_template is unset"
    it "should not return :html field if capnotify_deployment_notification_html_template is unset"

  end

end
