require 'sinatra/base'
require 'pg'
require 'json'

# Database module holds a single persistent connection.
# Resets on PG::Error so the next request reconnects.
module Database
  @conn = nil

  def self.connection
    @conn ||= PG.connect(
      host:     ENV['DB_HOST'],
      port:     ENV['DB_PORT'].to_i,
      user:     ENV['DB_USER'],
      password: ENV['DB_PASS'],
      dbname:   ENV['DB_NAME']
    )
  end

  def self.reset
    @conn = nil
  end
end

class App < Sinatra::Base
  configure do
    set :bind, '0.0.0.0'
    set :port, ENV.fetch('PORT', 8080).to_i
    # Empty permitted_hosts allows requests from any host — needed
    # for Zerops subdomains and custom domains. rack-protection
    # skips the check entirely when the list is empty.
    set :host_authorization, permitted_hosts: []
    # json_csrf 403s JSON responses whenever the Referer is
    # cross-origin — e.g. following the subdomain link from the
    # Zerops dashboard. The JSON-hijacking attack it guards
    # against only affected legacy browsers, so exempt it.
    set :protection, except: :json_csrf
  end

  # GET / — health check and greeting query.
  # Returns HTTP 200 with greeting from the database on success,
  # or HTTP 503 with error details if the database is unreachable.
  get '/' do
    content_type :json

    begin
      conn = Database.connection
      conn.exec('SELECT 1')
      result = conn.exec('SELECT message FROM greetings LIMIT 1')
      greeting = result[0]['message']

      status 200
      JSON.generate(
        type:     'ruby',
        greeting: greeting,
        status:   { database: 'OK' }
      )
    rescue PG::Error => e
      Database.reset
      status 503
      JSON.generate(
        type:     'ruby',
        greeting: nil,
        status:   { database: "ERROR: #{e.message}" }
      )
    end
  end
end
