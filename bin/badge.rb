require 'rubygems'
require 'lib/kickit'
require 'init'
require 'ap'

Kickit::RestSession.new('ssayles') do |ka|

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

