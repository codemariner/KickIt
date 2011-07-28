require File.expand_path(File.dirname(__FILE__) + "/spec_helper")

require 'net/http'

describe Kickit do
  describe Config do
    it "can store configuration values" do

      Kickit::Config.new do |config|
        config.rest_base_uri = 'foo'
        config.as = 'bar'
        config.developerKey = 'devkey'
      end

      Kickit::Config.rest_base_uri.should eql('foo')
      Kickit::Config.as.should eql('bar')
      Kickit::Config.developerKey.should eql('devkey')
    end
  end


  describe "A RestMethod" do
    before(:all) do
      
      @config = nil
        Kickit::Config.new do |config|
        config.rest_base_uri = 'http://api.kickapps.com/rest'
        config.as = '12345'
        config.developerKey = 'devkey'
        config.developerKey = '2d7d9f42'
        config.as = '193980'
        @config = config
      end

      class TestMethod < Kickit::RestMethod
        uri_path '/foo/bar/:as'
        desc 'test method'
        param :badgeId, :required => true
        param :location
      end

    end

    it "will submit a request to the configured uri path" do
      method = TestMethod.new 
      # since we're not using a session, we need to set the token ourselves
      session = Object.new
      def session.token 
          {'TOKEN' => '1234'}
      end
      method.session = session

      Net::HTTP.stub(:post_form) do |uri, params|
        uri.to_s.should eql("http://api.kickapps.com/rest/foo/bar/#{@config.as}")

        params.include?(:as).should be_true
        params.include?(:t).should be_true
        params[:t].should eql('1234')

        resp = Object.new
        def resp.body()
          '{"status": 1}'
        end
        resp
      end

      # response should be a hash after being parsed as json
      resp = method.execute(:badgeId => 'foo')
      resp.kind_of?(Hash).should be_true
      resp['status'].should eql(1)

    end


    it "should register subclasses when they are loaded" do
      Kickit::RestMethod.find(:test_method).should_not be_nil
      Kickit::RestMethod.find(:test_method).should eql(TestMethod)
    end


    it "will establish a session token with a given username" do
      Net::HTTP.stub(:post_form) do |uri, params|
        params[:username].should eql('ssayles')

        resp = Object.new
        def resp.body()
          '{"TOKEN": "1234"}'
        end
        resp
      end
      Kickit::RestSession.new('ssayles') do |session|
        session.token.should_not be_nil
        session.token['TOKEN'].should eql('1234')
      end
    end
  end

end


