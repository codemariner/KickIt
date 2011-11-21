require 'lib/kickit'

Kickit::Config.new do |config|

  config.developerKey = '99999999'
  config.as = 999999
  config.admin_username = 'sssssss'

  config.rest_base_uri = 'http://api.kickapps.com/rest'
  config.feed_url = 'http://cdnserve.a-feed.com/service/getFeed2.kickAction'
  config.soap_config = {
      :endpoint => {
          :uri => 'http://cambio.kickapps.net/soap/KaSoapSvc',
          :version => 1
      },
      :affiliate => {
        :username => 'KickitTeam',
        :email => 'KickitTeam@foo.com',
        :sitename => 'Kickit'
      }
  }
end
