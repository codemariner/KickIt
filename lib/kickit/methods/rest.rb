require 'net/http'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'json'
require 'rest_client'

module Kickit

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

    # returns a RestMethod by name, otherwise nil
    def api(method_name)
      clazz = ApiRegistry.find(method_name.to_sym)
      return unless clazz < RestMethod
      api_method = clazz.new
      api_method.session = self if api_method.kind_of? RestMethod
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

  # An ApiMethod that calls the KickApps REST API.
  #
  class RestMethod 
    include ApiMethod

    # a RestSession
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
      ApiRegistry.all.select do |name, clazz| 
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

      # check for required parameters
      self.class.params.each do |name,config|
        if (config[:required])
          unless parameters.keys.include?(name)
            e = Errors::ParameterRequiredError.new(name)
            raise e
          end
        end
      end
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

end


