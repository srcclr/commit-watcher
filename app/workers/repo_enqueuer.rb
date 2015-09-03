require_relative 'commit_collector'

class RepoEnqueuer
    include Sidekiq::Worker
    sidekiq_options :queue => :enqueue_repos

    def perform
        puts "going to enqueue all them repos now"
        100.times { CommitCollector.perform_async('someGuy/theirRepo') }
    end
end
