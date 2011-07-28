require 'rubygems'
require 'lib/kickit'
require 'init'
require 'ap'


u = Kickit::API::UserFeed.new

response = u.execute

items = response['rss']['channel']['item']

all_users = items.collect {|item| item['title']}


fan_users = []
Kickit::RestSession.new('ssayles') do |session|
  method = Kickit::API::UserAssociations.new
  method.session = session
  response = method.execute(:userId => '33325558', :operation => 'fans')
  fan_users = response['fans'].collect {|fan| fan['username']}
end


all_users.each do |name| 
  puts name unless fan_users.include? name
end
