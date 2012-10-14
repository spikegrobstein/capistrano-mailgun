require 'spec_helper'

describe Capistrano::Mailgun do

  let(:config) do
    Capistrano::Configuration.new
  end

  before do
    config.load do
      Capistrano.plugin :mailgun, Capistrano::Mailgun
    end
  end

  let!(:mailgun) { config.mailgun }

  context '#buid_recipients' do
    let(:email_1) { 'spike@example.com' }
    let(:email_2) { 'bob@example.com' }

    def build_recipients(recipients)
      mailgun.send(:build_recipients, recipients)
    end

    it "should accept a single recipient (not an array)" do
      build_recipients(email_1).should == [email_1]
    end

    it "should accept an array of recipeints" do
      build_recipients( [email_1, email_2] ).should == [email_1, email_2]
    end

    it "should deduplicate emails in the recipients" do
      build_recipients( [email_1, email_2, email_1] ).should == [email_1, email_2]
    end

    context "when working with unqualified email addresses" do
      before(:all) do
        config.load do
          set :mailgun_recipient_domain, 'another.com'
        end
      end

      it "should add the mailgun_recipient_domain to any unqualified email addresses" do
        build_recipients( %w( spike ) ).should == ['spike@another.com']
      end

      it "should accept a mix of qualified and unqualified email addresses" do
        build_recipients( [email_1, 'spike']).should == [email_1, 'spike@another.com']
      end

    end


  end

  context "#find_template" do

    # future behavior might be different
    it "should return the path passed to it" do
      mailgun.find_template('asdf').should == 'asdf'
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

  end

  context "#process_send_email_options" do

    it "should set text to the rendered text template if text_template is passed" do
      File.should_receive(:open).and_return('template')

      mailgun.send(:process_send_email_options, :text_template => 'template')[:text].should == 'template'
    end

    it "should not change text if no text_template is passed" do
      ERB.should_not_receive(:new)
      File.should_not_receive(:open)

      mailgun.send(:process_send_email_options, :text => 'normal text')[:text].should == 'normal text'
    end

    it "should set html to the rendered html template if html_template is passed" do
      File.should_receive(:open).and_return('template')

      mailgun.send(:process_send_email_options, :html_template => 'template')[:html].should == 'template'
    end

    it "should not change html if no html_template is passed" do
      ERB.should_not_receive(:new)
      File.should_not_receive(:open)

      mailgun.send(:process_send_email_options, :html => 'normal html')[:html].should == 'normal html'
    end

  end

end
