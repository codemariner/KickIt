require 'rubygems'
require 'lib/kickit'
require 'init'
require 'ap'


u = Kickit::API::UserFeed.new

response = u.execute('adminTag=celebrity')

items = response['rss']['channel']['item']

items.each do |item|

  Kickit::RestSession.new(item['title']) do |session|
    method = Kickit::API::AddOrRemoveFriend.new
    method.session = session
    ap method.execute({:friendId => '33325558', :operation => 'add'})
  end

end
