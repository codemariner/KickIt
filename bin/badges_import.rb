$LOAD_PATH.unshift File.dirname(__FILE__)

# this script assumes that user data has been loaded into mongodb
# database cambio collection users
#
require 'common'
require 'mongo'
require 'ap'

db = Mongo::Connection.new.db('cambio')
coll = db.collection('users')
coll.create_index("admin_tags")

users = coll.find({"admin_tags" => /user/}, {:sort => ['points',:desc]})

@error_log = File.new('error.log','w')
def get_user_id(user, ka)
  begin
  resp = ka.api(:create_token).execute(
            :username => user["username"],
            :developerKey => Kickit::Config.developerKey,
            :idType => 'username')
  resp['userId']
  rescue Exception => e
    @error_log << "Error getting userid for #{user["username"]}: #{e.message}"
    @error_log << e.backtrace.join("\n")
  end
end

def get_badges(user, ka)
    userid = user["userId"]
    begin
      resp = ka.api(:user_badges).execute({:pageSize => 100, :pgNum => 1, :user_id => userid})
    rescue Exception => e
      @error_log << "Error getting badges for #{user["username"]}: #{e.message}"
      @error_log << e.backtrace.join("\n")
    end
    if resp['status'] == "1"
      user["badges"] = resp["badges"] 
      true
    else
      @error_log << "could not get badges for #{user["username"]}: #{resp.inspect}"
      false
    end
end

Kickit::RestSession.new('ssayles') do |ka|

  count = 0
  num_users = users.count
  puts "processing #{num_users} users"
  users.each do |user|
    count += 1
    s = (count.to_f / num_users.to_f) * 100
    printf((s < 100 ? "\rProgress:  %02d\%" : "\rProgress: %3d\%"), s)
    $stdout.flush 
    do_update = false
    unless user["userId"]
      userid = get_user_id(user, ka)
      next unless userid
      user["userId"] = userid
      do_update = true
    end

    do_update = true if get_badges(user, ka)

    if do_update
      begin
        coll.update({"_id" => user["_id"]}, user)
      rescue Exception => e
        @error_log << "could not save to db for user #{user['username']}: #{e.message}"
        @error_log << e.backtrace.join("\n")
      end
    end
  end

end

users.each do |user|
  puts user["username"]
end
