require 'net/http'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'json'
require 'rest_client'

module Kickit

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


