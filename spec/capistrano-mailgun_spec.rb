require 'spec_helper'

describe Capistrano::Mailgun do

  let!(:config) do
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

end
