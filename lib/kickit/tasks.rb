require 'ap'

namespace :kickit do

  Kickit::RestMethod.all.each do |name, method_class|

    args = method_class.params.keys

    # add multipart parameter arguments
    if (method_class.multipart)
      method_class.multipart.each do |param_name|
        args << param_name
      end
    end

    desc method_class.desc
    task name, args do |t, args|
      if method_class == Kickit::API::CreateToken
        args['developerKey'] = Kickit::Config.developerKey
        create_token = method_class.new
        resp = create_token.execute(args.to_hash)
        ap resp
      else
        # create the session specifically with the admn username
        # as we're probably not being supplied one otherwise
        # and this is from the command line anyway
        session = Kickit::RestSession.new(Kickit::Config.admin_username)
        method = method_class.new
        method.session = session

        resp = method.execute(args.to_hash)
        ap resp
      end
    end
  end  


  Kickit::RssMethod.all.each do |name, method_class|
    desc method_class.desc
    task name, [:query] do |t, args|
      rss = method_class.new
      response = rss.execute(args.to_hash[:query])
      ap response
    end
  end
end

