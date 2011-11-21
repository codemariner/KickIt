module Kickit

  module API
   
    class UserFeed < RssMethod
      desc "list users from feed"

      param :mediaType, 'user'
    end

    class PhotosFeed < RssMethod
      desc "list photos for a specific user"

      param :mediaType, 'photo'
    end
  end

end


