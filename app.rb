require 'active_support/all'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sprockets'
require 'sprockets-helpers'
require 'slim'
require 'pry'

class QunitTestSuite < Sinatra::Base
  set :sprockets, Sprockets::Environment.new(root)
  set :assets_prefix, '/assets'
  set :digest_assets, false

  configure do
    sprockets.append_path File.join(root, "lib")
    sprockets.append_path File.join(root, "test")
    sprockets.append_path File.join(root, "vendor/javascripts")
    sprockets.append_path File.join(root, "vendor/stylesheets")
    Sprockets::Helpers.configure do |config|
      config.environment = sprockets
      config.prefix      = assets_prefix
      config.digest      = digest_assets
      config.public_path = public_folder
      config.debug       = true
    end
  end

  helpers do
    include Sprockets::Helpers
  end

  get '/assets/*' do
    asset_name = params["splat"].join("/")
    asset = settings.sprockets[asset_name]
    raise Sinatra::NotFound.new(asset_name) unless asset.present?
    content_type asset.content_type
    asset.body
  end

  get '/' do
    slim :qunit
  end
end
