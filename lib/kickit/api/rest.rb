module Kickit

  # this module is just a place to store all of the API method
  # configurations.
  module API
   
    class CreateToken < RestMethod
      desc 'Obtains a token used when calling any subsequent requests to the API.'
      uri_path '/token/create/:username/:as'

      param :developerKey, :required => true
      param :username, :required => true
      param :idType #username or email
    end

    class AddBadge < RestMethod
      desc 'Add a badge'
      uri_path '/badge/add/:as'

      param :location
      param :name
      param :verbosename
      param :url

    end
    
    class EditBadge < RestMethod
      desc 'Edit a badge from the available set of badges in the BET community'
      uri_path '/badge/edit/:as'

      param :badgeId, :required => true
      param :published
      param :name
    end

    class UserBadgeStatus < RestMethod
      desc 'Returns progress information on badges for a given user and optionally a location'
      uri_path 'user/badges/getstatus/:as'

      param :user_id, :required => true
      param :location
    end


    class ListActions < RestMethod
      desc 'Lists all badge actions in the system'
      uri_path '/badgeactions/list/:as'
    end

    class AddAction < RestMethod
      desc 'Adds a new badge action to the system'
      uri_path '/badgeaction/add/:as'
      
      param :name, :required => true
    end

    class AddBadgeRequirement < RestMethod
      desc 'Adds badge requirements into the system'
      uri_path '/badgerequirement/add/:as'

      param :badgeId, :required => true
      param :actionId, :required => true
      param :location, :required => true
      param :quantity
      param :published, :default => false
    end

    class ListBadgeRequirements < RestMethod
      desc 'Returns a list of all Badge Requirements for the provided badgeId'
      uri_path '/badgerequirement/list/:as'

      param :badgeId
    end

    class EditBadgeRequirement < RestMethod
      desc 'Updates badge requirement'
      uri_path '/badgerequirement/edit/:as'

      param :requirementId, :required => true
      param :badgeId, :required => true
      param :location, :required => true
      param :quantity
      param :published, :default => false
      param :actionId, :default => false
    end

    class ListBadges < RestMethod
      desc 'This is an admin method that will list all badges for an AS either site-wide or for a specific location.'
      uri_path '/badges/list/:as'

      param :location
      param :published
    end

    class UserProfile < RestMethod
      desc 'Retrievs a specific user profile.'
      uri_path '/user/profile/:userid/:as'

      param :userid, :required => true
      param :include, :required => false
    end


    class UserBadges < RestMethod
      desc 'Retrieves badges belonging to a specified user'
      uri_path '/user/badges/get/:as'

      param :user_id, :required => true
      param :pgNum
      param :pageSize
    end

    class UserAssociations < RestMethod
      desc 'Get a list of a member’s friends, fans, and other members they are a fan of'
      uri_path '/member/:operation/get/:userId/:as'
      
      param :operation, :required => true
      param :userId, :required => true
    end

    class AddUserAction < RestMethod
      desc 'Add user actions to aid in the awarding users achievement based badges'
      uri_path '/user/action/add/:as'

      param :user_id, :required => true
      param :actionId, :required => true
      param :location, :required => true

      param :quantity
    end

    class SetProfilePhoto < RestMethod
      desc 'Set user profile'
      uri_path '/user/profile/photo/add/:as'
      param :photoId, :required => true
    end

    class AddPoints < RestMethod
      desc 'Add user points offset'
      uri_path '/points/add/:userId/:as'

      param :userId, :required => true
      param :addToOffset, :required => true
    end

    class AddOrRemoveFriend < RestMethod
      desc 'Add or remove friend. operation is one of \'add\' or \'remove\''
      uri_path '/friend/:operation/:friendId/:as'

      param :operation, :required => true
      param :friendId, :required => true
    end

    class AddOrRemoveFavorite < RestMethod
      desc 'adds or removes a media as a favorite'
      uri_path '/favorite/:operation/:mediaType/:mediaId/:as'

      param :operation, :required => true
      param :mediaType, :required => true
      param :mediaId, :required => true
      param :url
    end

    class FavoriteMediaCheck < RestMethod
      desc 'check if a member has favorited a media'

      uri_path '/check/favorite/:mediaType/:mediaId/:as'

      param :mediaType, :required => true
      param :mediaId, :required => true
      param :url
    end

    class FavoriteMedia < RestMethod

      desc "retrieves user's favorite media"
      uri_path 'user/media/:userid/:as'

      param :userid, :required => true
      param :mediaType
    end

    class ListMemberMedia < RestMethod
      desc 'retrieve a users media'
      uri_path '/user/media/:userid/:as'

      param :mediaType, :required => true
      param :userid, :required => true
    end

    class AddExternalMedia < RestMethod
      desc 'add external media url'
      uri_path '/externalmedia/add/:as'

      param :name, :required => true
      param :pathToMedia, :required => true
      param :allowPublicTagging
    end

    class RetrieveExternalMedia < RestMethod
      desc 'retrieve external media data'
      uri_path '/externalmedia/:as'

      param :url, :required => true
    end

    class UploadMedia < RestMethod
      desc "upload memeber media"
      uri_path '/upload/:mediaType/:as'
      multipart :media

      param :mediaType, :required => true
      param :name, :required => true
      param :isProfileImage
    end

    class DeleteMedia < RestMethod
      desc "delete a media"
      uri_path '/deletemedia/:as'

      param :mediaType, :required => true
      param :mediaId, :required => false
      param :url, :required => false
    end

    class RetrieveExternalMedia < RestMethod
      desc "Retrieve media metadata"
      uri_path '/externalmedia/:as'

      param :url, :required => true
    end

    class RetrieveMediaMeta < RestMethod
      desc "Retrieve media metadata"
      uri_path '/mediainfo/:mediaType/:mediaId/:as'

      param :mediaType, :required => true
      param :mediaId, :required => true
    end

    class FlagMedia < RestMethod
      desc "add or remove flag from media"

      uri_path '/flag/:operation/:mediaType/:mediaId/:as'

      param :mediaType, :required => true
      param :operation, :required => true
      param :mediaId, :required => true
    end

    class ApproveMedia < RestMethod
      desc "approve member media"

      uri_path '/media/approve/:mediaType/:mediaId/:as'

      param :mediaType, :required => true
      param :mediaId, :required => true
    end

    class AddPoints < RestMethod
      desc "Add to memeber offset"

      uri_path '/points/add/:userId/:as'

      param :userId , :required => true
    end

    class AddTag < RestMethod
      desc "Add tags to media, members, and groups"

      uri_path '/tags/add/:mediaType/:mediaId/:as'

      param :mediaType, :required => true
      param :mediaId, :required => true
      param :url 
      param :tags 
    end

    class GetTagCount < RestMethod
      desc "Retrieves tag count for media"

      uri_path '/tags/count/:mediaType/:as'

      param :mediaType, :required => true
      param :mediaId, :required => true
      param :url 
    end
  end

end
