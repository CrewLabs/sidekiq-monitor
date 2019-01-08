require "sidekiq"
require "sidekiq/web"

map "/" do
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username == ENV["USERNAME"] && password == ENV["PASSWORD"]
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV["REDIS_URL"], size: 1 }
  end

  run Sidekiq::Web

  map "/staging" do
    Sidekiq.configure_client do |config|
      config.redis = { url: ENV["REDIS_STAGING_URL"], size: 1 }
    end

    run Sidekiq::Web
  end
end
