class CommitCollector
    include Sidekiq::Worker
    sidekiq_options :queue => :collect_commits

    def perform(repo_name)
        puts "I'm working so hard collecting them commits!"
    end
end
