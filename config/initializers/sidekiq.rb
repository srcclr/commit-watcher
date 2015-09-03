require 'sidekiq'
require 'sidekiq-cron'

Sidekiq.configure_server do |config|
    schedule_file = 'config/schedule.yml'

    Sidekiq::Cron::Job.load_from_hash(YAML.load_file(schedule_file)) if File.exists?(schedule_file)
end
