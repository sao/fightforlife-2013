require 'sinatra'
require 'sinatra/static_assets'
require 'sinatra/assetpack'
require 'sass'
require 'vimeo'
require 'stripe'
require 'pony'

configure :production do
  require 'newrelic_rpm'
  require 'rack/ssl-enforcer'
  use Rack::SslEnforcer, :only => '/donate'
end

root = ::File.dirname(__FILE__)
require ::File.join( root, 'app' )
run FightForLifeApp.new
