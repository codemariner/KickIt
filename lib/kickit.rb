require 'net/http'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'json'
require 'rest_client'

module Kickit

  # Configuration for kickapps API.  Perform configuration in some kind of
  # initializer.
  #
  #   KickIt::Config.new do |config|
  #     config.rest_base_uri: 'http://api.kickapps.com/rest'
  #     config.as: '822134'
  #     config.developerKey: '2i4js7fx'
  #   end
  #
  # The api token may be set here, but typically you will start a session
  # which will take care of this for you.
  #
  class Config
    class << self; attr_accessor :rest_base_uri, :as, :developerKey, :token, :admin_username, :feed_url; end

    def initialize(&block)
      yield Config if block_given?
    end
  end


  # This helps to manage a specific user's session against the API in
  # which the user must first obtain and utilize a session token for
  # making any subsequent requests to the API.
  # 
  # Example:
  #
  #   Kickit::RestSession.new(username) do |session|
  #     resp = session.api(:user_profile).execute(:userId => userId)
  #     resp['UserProfile']
  #   end
  #
  class RestSession

    # the established kickapps rest api session token
    attr_accessor :token

    # username of the kickapps user the session is being created for
    attr_reader :username

    def initialize(username, set_token = true)
      @username = username
      refresh_token() if set_token
      yield self if block_given?
    end

    def api(method_name)
      clazz = ApiMethod.find(method_name.to_sym)
      api_method = clazz.new
      api_method.session = self if clazz.kind_of? RestMethod
      api_method
    end

    private
    
    # attempts to establish a token only if one does not already exist
    def refresh_token
      return if token
      refresh_token!
    end

    # grab a new token no matter what
    def refresh_token!
      create_token = Kickit::API::CreateToken.new
      resp = create_token.execute(:username => username,
                                  :developerKey => Kickit::Config.developerKey)
      @token = resp
    end

  end


  class ApiMethod
    @@register = {}
    
    # all registered api method implementations
    @@register = {}
    def execute(parameters={})
    end

    def self.all()
      @@register
    end

    def self.desc(value=nil)
      return @description unless value
      @description = value
    end

    def self.find(method_name)
      @@register[method_name]
    end

    # detect when subclasses are created and register them by a
    # parameterized name
    def self.inherited(subclass)
      return if subclass == RssMethod or subclass == RestMethod
      # register subclasses
      name = subclass.name.demodulize.underscore.to_sym
      if @@register[name]
        # TODO: do smart integration with logging
        puts "warning: api method already registered for #{@@register[name]}.  This has been overridden by #{subclass.name}"
      end
      @@register[subclass.name.demodulize.underscore.to_sym] = subclass
    end

  end

  class RssMethod < ApiMethod
    def self.param(name, value)
      self.params[name] = value
    end

    def self.params
      @params ||= {}
    end

    def self.all
      ApiMethod.all.select do |name, clazz| 
        clazz < RssMethod 
      end
    end

    def execute(queryString="")
      parameters = prepare(queryString)
      uri = URI.parse(Kickit::Config.feed_url)

      path = "#{uri.path}?".concat(parameters.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&'))
      response = Net::HTTP.get(uri.host, path)
      Hash.from_xml(response)
    end

    private
    def prepare(queryString)
      parameters = {}
      parameters[:as] = Kickit::Config.as

      if (queryString and !queryString.empty?)
        params = queryString.split('&')
        params.each do |param|
          name, value = param.split("=")
          parameters[CGI.escape(name)] = CGI.escape(value)
        end
      end

      parameters = self.class.params.merge(parameters)
      parameters
    end
  end

  class RestMethod < ApiMethod

    attr_accessor :session


    def self.uri_path(path=nil)
      return @uri_path unless path
      @uri_path = path
    end

    def self.param(name, config={})
      self.params[name] = config
    end

    def self.params
      @params ||= {}
    end

    def self.multipart(*file_params)
      return @multipart unless !file_params.empty?
      @multipart = file_params
    end

    def self.all
      ApiMethod.all.select do |name, clazz| 
        clazz < RestMethod 
      end
    end

    # submits the request and returns a Hash of the response from the API.
    # If the response is not valid, nil is returned.
    # Callers will need to interogate the response Hash to see if the
    # request encountered some kind of error
    #
    # TODO: instead of returning a hash, provide some way to map the
    # response to some kind of appropriate object.
    def execute(parameters={})
      parameters = parameters.clone
      prepare(parameters)
      
      # TODO: abstract the kind of http client we're using
      # TODO: ensure we have some kind of timeout handling
      url = URI.parse(create_url(parameters))

      puts "Calling: #{url.to_s}"
      puts "  parameters: #{parameters.inspect}"
      response = nil

      # add multipart parameters
      if self.class.multipart
        post_data = parameters
        self.class.multipart.each do |param|
          if parameters[param]
            file_path = parameters.delete(param)
            post_data[param] = File.new(file_path)
          end
        end

        response = RestClient.post(url.to_s, post_data).to_str
      else
        response = Net::HTTP.post_form(url, parameters).body
      end

      begin
        return JSON.parse(response)
      rescue JSON::ParserError => e
        # it's most likely that the request was invalid and the server has
        # sent back an error page full of html
        # just return nil
      end
    end

    private

    def prepare(parameters)
      parameters[:as] = Kickit::Config.as.to_s
      parameters[:t] = session.token['TOKEN'] if session
    end

    # constructs the url based on configuration while taking care to
    # perform any kind of string interopolation.
    # This assumes that the list parameters has been made complete for the
    # call (i.e. any t and as parameters have been added)
    def create_url(parameters)
      # "/badges/add/:as
      path = uri_path
      if path =~ /:/
        # ["", "badges", "add", ":as"]
        parts = path.split('/')
        path = ""
        parts.each do |part|
          next if part == "" or part.nil?
          path << '/'
          if part =~ /:/
            part_name = /:(.*)/.match(part)[1]
            # parameters[:as]
            part = parameters[part_name.to_sym]
          end
          path << part
        end
      end
      url = "#{Kickit::Config.rest_base_uri}#{path}"
    end
    def uri_path
      self.class.instance_eval {self.uri_path}
    end
  end


  module API
   
    #
    class CreateToken < RestMethod
      desc 'Obtains a token used when calling any subsequent requests to the API.'
      uri_path '/token/create/:username/:as'

      param :developerKey
      param :username, :required => true
    end

    class EditBadge < RestMethod
      desc 'Edit a badge from the available set of badges in the BET community'
      uri_path '/badge/edit/:as'

      param :badgeId, :required => true
      param :published
    end

    class ListActions < RestMethod
      desc 'Lists all badge actions in the system'
      uri_path '/badgeactions/list/:as'
    end

    class AddAction < RestMethod
      desc 'Adds a new badge action to the system'
      uri_path '/badgeaction/add/:as'
      
      param :name, :required => true
    end

    class AddBadgeRequirement < RestMethod
      desc 'Adds badge requirements into the system'
      uri_path '/badgerequirement/add/:as'

      param :badgeId, :required => true
      param :actionId, :required => true
      param :location, :required => true
      param :quantity
      param :published, :default => false
    end

    class ListBadgeRequirements < RestMethod
      desc 'Returns a list of all Badge Requirements for the provided badgeId'
      uri_path '/badgerequirement/list/:as'

      param :badgeId
    end

    class ListBadges < RestMethod
      desc 'This is an admin method that will list all badges for an AS either site-wide or for a specific location.'
      uri_path '/badges/list/:as'

      param :location
      param :published
    end

    class UserProfile < RestMethod
      desc 'Retrievs a specific user profile.'
      uri_path '/user/profile/:userid/:as'

      param :userid, :required => true
    end


    class UserBadges < RestMethod
      desc 'Retrieves badges belonging to a specified user'
      uri_path '/user/badges/get/:as'

      param :user_id, :required => true
      param :pgNum
      param :pageSize
    end

    class UserAssociations < RestMethod
      desc 'Get a list of a member’s friends, fans, and other members they are a fan of'
      uri_path '/member/:operation/get/:userId/:as'
      
      param :operation, :required => true
      param :userId, :required => true
    end

    class AddUserAction < RestMethod
      desc 'Add user actions to aid in the awarding users achievement based badges'
      uri_path '/user/action/add/:as'

      param :user_id, :required => true
      param :actionId, :required => true
      param :location, :required => true

      param :quantity
    end

    class AddOrRemoveFriend < RestMethod
      desc 'Add or remove friend. operation is one of \'add\' or \'remove\''
      uri_path '/friend/:operation/:friendId/:as'

      param :operation, :required => true
      param :friendId, :required => true
    end

    class ListMemberMedia < RestMethod
      desc 'retrieve a users media'
      uri_path '/user/media/:userid/:as'

      param :mediaType, :required => true
      param :userid, :required => true
    end

    class UploadMedia < RestMethod
      desc "upload memeber media"
      uri_path '/upload/:mediaType/:as'
      multipart :media

      param :mediaType, :required => true
      param :name, :required => true
      param :isProfileImage
    end


    class UserFeed < RssMethod
      desc "list users from feed"

      param :mediaType, 'user'
    end

    class PhotosFeed < RssMethod
      desc "list photos for a specific user"

      param :mediaType, 'photo'
    end
  end

end


