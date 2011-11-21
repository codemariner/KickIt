require 'handsoap'

module Kickit
  class SoapMethod < Handsoap::Service
    include ApiMethod

    # calling this after config has been initialized
    Kickit::Config.post_config {|config|
      if (config.soap_config)
        endpoint config.soap_config[:endpoint]
      end
    }

    def initialize()
      @doc = nil
      @af_username = Kickit::Config.soap_config[:affiliate][:username]
      @af_email = Kickit::Config.soap_config[:affiliate][:email]
      @af_sitename = Kickit::Config.soap_config[:affiliate][:sitename]
    end

    def on_create_document(doc)
      # register namespaces for the request
      doc.alias 'tns', 'http://soap.services.kickapps.com'
      header = doc.find('Header')

      header.add('AffiliateAuthenticationToken') do |auth|
        auth.set_attr 'xmlns', "http://schemas.kickapps.com/services/soap"

        auth.add('AffiliateUserName', @af_username)
        auth.add('AffiliateUserEmail', @af_email)
        auth.add('AffiliateSiteName', @af_sitename)
      end
      @doc = doc
    end
    
    def on_response_document(doc)
      # register namespaces for the response
      doc.add_namespace 'ns', 'http://soap.services.kickapps.com'
    end
  
  end
end
