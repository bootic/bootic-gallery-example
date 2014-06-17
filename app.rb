require 'bundler/setup'
require 'sinatra/base'
require "rack/cache"
require 'bootic_client'
require 'dalli'
require 'bootic_client/stores/memcache'

CACHE_STORE = BooticClient::Stores::Memcache.new(
    (ENV["MEMCACHIER_SERVERS"] || "").split(","),
    username: ENV["MEMCACHIER_USERNAME"],
    password: ENV["MEMCACHIER_PASSWORD"],
    failover: true,
    socket_timeout: 1.5,
    socket_failure_delay: 0.2,
    value_max_bytes: 10485760
  )

BooticClient.configure do |c|
  c.client_id = ENV['BOOTIC_CLIENT_ID']
  c.client_secret = ENV['BOOTIC_CLIENT_SECRET']
  c.logging = true
  c.cache_store = CACHE_STORE
end

class App < Sinatra::Base
  use Rack::Cache, metastore: CACHE_STORE.client, entitystore: CACHE_STORE.client

  before do
    cache_control :public, :must_revalidate, max_age: 3600
  end

  def client
    @client ||= BooticClient.client(:client_credentials, scope: 'public', access_token: CACHE_STORE.read('access_token')) do |new_token|
      puts "NEW TOKEN #{new_token}"
      CACHE_STORE.write('access_token', new_token)
    end
  end

  def root
    @root ||= client.root
  end

  get '/?' do
    @path = '/'
    @products = root.all_products(
      per_page: 28,
      sort: 'updated_on.desc',
      account_status: 'active,free',
      q: params[:q]
    )

    erb :products
  end

  get '/shops' do
    @path = "/shops"
    @shops = root.all_shops(
      status: 'active,free',
      sort: 'updated_on.desc',
      q: params[:q]
    )
    erb :shops
  end

  get '/:shop_subdomain' do |subdomain|
    @path = "/#{subdomain}"
    @products = root.all_products(
      shop_subdomains: subdomain,
      per_page: 28,
      sort: 'updated_on.desc',
      q: params[:q]
    )

    erb :products
  end

end