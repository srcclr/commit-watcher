require File.expand_path('../boot', __FILE__)

require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'sprockets/railtie'

Bundler.require(*Rails.groups)

module CommitWatcher
  class Application < Rails::Application

    Sequel::Database.extension :pagination

    config.action_mailer.default_url_options = { host: 'api.my_app.dev:3000' }
  end
end
