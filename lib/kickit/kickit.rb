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


  # A place to store all api methods that have been created
  #
  module ApiRegistry
    # all registered api method implementations
    @@register = {}
 
    def self.add(method_name, method_class)
      @@register[method_name] = method_class
    end

    # Removes an ApiMethod by it's given name.  This is mostly to support
    # testing purposes.
    #
    def self.remove(method_name)
      @@register.delete(method_name)
    end
    
    # returns all registered ApiMethod instances.
    def self.all()
      @@register
    end
    
    # Returns a registered ApiMethod by it's name.
    #
    def self.find(method_name)
      @@register[method_name]
    end
        
  end

  # represents a method in one of the KickApps APIs. It is intended that
  # including classes will represent one of the type of KickApps APIs like
  # REST, SOAP, or RSS.  This will cause including classes to
  # automatically register their subclasses in the ApiRegistry such that:
  #
  #   class RestMethod
  #     include ApiMethod
  #   end
  #
  #   class GetUserProfile < RestMethod
  #   end
  #
  #   ApiRegistery.find('get_user_profile')
  #   => GetUserProfile
  #
  module ApiMethod
    
    def self.included(base)
      base.class_eval do
    
        # Performs the API call.  Subclasses should override this.
        def execute(parameters={})
          raise "Subclasses of #{base.name} must implement execute()."
        end
    
        # A description of the ApiMethod.  This is particularly used
        # when displaying information about the call.
        def self.desc(value=nil)
          return @description unless value
          @description = value
        end
    
        # detect when subclasses are created and register them by a
        # parameterized name
        #
        def self.inherited(subclass)
          # register subclasses
          name = subclass.name.demodulize.underscore.to_sym
          if ApiRegistry.find(name)
            # TODO: do smart integration with logging
            puts "warning: api method already registered for #{ApiRegistry.find[name]}.  This has been overridden by #{subclass.name}"
          end
          ApiRegistry.add(subclass.name.demodulize.underscore.to_sym,subclass)
        end
      end

    end 

  end

end


require 'kickit/methods/rest'
require 'kickit/methods/rss'
