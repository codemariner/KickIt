module Kickit

  module Errors
    class ParameterRequiredError < StandardError
      attr_reader :parameter_name
      def initialize(parameter_name)
        @parameter_name = parameter_name
      end
      def message
        "Parameter '#{@parameter_name}' is missing."
      end
    end
  end

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



  # represents a method in one of the KickApps APIs.
  #
  class ApiMethod
    
    # all registered api method implementations
    @@register = {}

    # Performs the API call.  Subclasses should override this.
    def execute(parameters={})
      raise "Subclasses of ApiMethod must implement execute()."
    end

    # returns all registered ApiMethod instances.
    def self.all()
      @@register
    end

    # A description of the ApiMethod.  This is particularly used
    # when displaying information about the call.
    def self.desc(value=nil)
      return @description unless value
      @description = value
    end

    # Returns a registered ApiMethod by it's name.
    #
    def self.find(method_name)
      @@register[method_name]
    end
    
    # Removes an ApiMethod by it's given name.  This is mostly to support
    # testing purposes.
    #
    def self.remove(method_name)
      @@register.delete(method_name)
    end

    # detect when subclasses are created and register them by a
    # parameterized name
    #
    def self.inherited(subclass)
      # prevent the RssMethod and RestMethod classes themselves from being
      # registered.  Yes, this probably isn't the cleanest way to do this.
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

  # A call that requests from the KickApps RSS API.
  class RssMethod < ApiMethod
    # a place for subclasses to store what parameters are expected and
    # what default values to use.
    def self.param(name, value)
      self.params[name] = value
    end

    def self.params
      @params ||= {}
    end

    # returns all RssMethod subclasses
    def self.all
      ApiMethod.all.select do |name, clazz| 
        clazz < RssMethod 
      end
    end

    def execute(queryString="")
      parameters = prepare(queryString)
      uri = URI.parse(Kickit::Config.feed_url)

      path = "#{uri.path}?".concat(parameters.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&'))
      puts path
      response = Net::HTTP.get(uri.host, path)
      Hash.from_xml(response)
    end

    private

    # takes care of setting up the parameters to pass
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

end


require 'kickit/methods/rest'
require 'kickit/methods/rss'
