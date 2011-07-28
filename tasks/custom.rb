require 'ap'
require 'rest_client'
require 'active_support/core_ext/string'
require 'active_support/core_ext/hash'
require 'json'

namespace :kickit do

  desc "generates badges sprite css based on KA badge data.  This assumes that the badges are listed alphabetically in the sprite."
  task "badge_css" do
    ka = Kickit::RestSession.new('ssayles')
    badges = ka.api(:list_badges).execute(:published => true)['badges']

    y = 0

    badges.each do |badge|
     doc = <<-eos
/* #{badge['name']} */
.badge_#{badge['badgeId']}_large {
  background-image: url(http://o.aolcdn.com/os/cambio/images/badges_sprite.png);
  background-position: 0px -#{y}px;
  width: 60px;
  height: 60px;
  display: block;
  text-indent: -99em;
}
.badge_#{badge['badgeId']}_medium {
  background-image: url(http://o.aolcdn.com/os/cambio/images/badges_sprite.png);
  background-position: -60px -#{y}px;
  width: 36px;
  height: 36px;
  display: block;
  text-indent: -99em;
}
.badge_#{badge['badgeId']}_small {
  background-image: url(http://o.aolcdn.com/os/cambio/images/badges_sprite.png);
  background-position: -96px -#{y}px;
  width: 32px;
  height: 32px;
  display: block;
  text-indent: -99em;
}
  eos
      puts doc
      y += 60
    end
  end

end

namespace :http do

  desc "prints response from http request"
  task :get, [:url, :parse_type] do |t, args|
    payload_type = args[:parse_type]
    response = RestClient.get(args[:url]).to_str
    if (args[:parse_type] == 'json')
      ap JSON.parse(response)
    elsif (args[:parse_type] == 'xml')
      ap Hash.from_xml(response)
    else
      ap response
    end
  end

end
