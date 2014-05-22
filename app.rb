require 'bundler/setup'
require 'sinatra/base'
require 'hyperresource'
require "rack/cache"

class BooticAPI < HyperResource
  self.root = 'https://api.bootic.net/v1'
  self.headers = {
    'Accept' => 'application/json',
    'Authorization' => "Bearer #{ENV['BOOTIC_ACCESS_TOKEN']}"
  }
  
end

class App < Sinatra::Base
  use Rack::Cache

  before do
    cache_control :public, :must_revalidate, max_age: 3600
  end

  def client
    @client ||= BooticAPI.new.get
  end

  get '/?' do
    @path = '/'
    @products = client.products.where(
      per_page: 28,
      sort: 'updated_on.desc', 
      q: params[:q]
    ).get

    erb :index
  end

  get '/:shop_subdomain' do |subdomain|
    @path = "/#{subdomain}"
    @products = client.products.where(
      shop_subdomains: subdomain, 
      per_page: 28,
      sort: 'updated_on.desc', 
      q: params[:q]
    ).get

    erb :index
  end
end