require 'lib/kickit'

Kickit::Config.new do |config|
  config.developerKey = '2d7d9f42'
  config.as = 193980
  config.admin_username = 'ssayles'
  config.rest_base_uri = 'http://api.kickapps.com/rest'
  config.feed_url = 'http://cdnserve.a-feed.com/service/getFeed2.kickAction'
end
