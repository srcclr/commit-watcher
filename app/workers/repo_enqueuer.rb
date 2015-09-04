require_relative 'commit_collector'
require_relative '../models/configuration'

class RepoEnqueuer
    include Sidekiq::Worker
    sidekiq_options :queue => :enqueue_repos

    def perform
        puts "going to enqueue all them repos now: #{Configuration.first}"
        10.times { CommitCollector.perform_async('someGuy/theirRepo') }
    end
end
