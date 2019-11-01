require "syro"
require "sidekiq"
require "sidekiq/web"
require "sidekiq/grouping/web"

Sidekiq::Web.set :session_secret, ENV["SESSION_SECRET"]

Workers = Syro.new do
  def sidekiq_web_for(url)
    Sidekiq.configure_client do |config|
      config.redis = { url: url, size: 1 }
    end

    run Sidekiq::Web
  end

  on "production" do
    sidekiq_web_for(ENV["REDIS_URL"])
  end

  on "staging" do
    sidekiq_web_for(ENV["REDIS_STAGING_URL"])
  end

  get do
    res.text "Hello"
  end
end

Root = Syro.new do
  get do
    res.html <<-HTML
    <html>
    <body>
    <h1>Workers</h1>
    <ul>
      <li>
        <a href="/workers/production">Production</a>
      </li>

      <li>
        <a href="/workers/staging">Staging</a>
      </li>
    </ul>
    </body>
    </html>
    HTML
  end
end

Admin = Syro.new do
  on("workers") { run Workers }
  get { run Root }
end

App = Rack::Builder.new do
  use Rack::MethodOverride
  use Rack::Session::Cookie, secret: ENV["SESSION_SECRET"]
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username == ENV["USERNAME"] && password == ENV["PASSWORD"]
  end

  run Admin
end

run App
