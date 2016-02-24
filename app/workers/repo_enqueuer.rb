require_relative 'commit_collector'
require_relative '../models/configurations'
require_relative '../models/projects'

class RepoEnqueuer
    include Sidekiq::Worker
    sidekiq_options :queue => :enqueue_repos

    def perform
        projects = Projects.where { next_crawl <= Time.now.to_i }
        config = Configurations.first unless projects.empty?
        projects.each do |p|
            rule_ids = JSON.parse(config[:global_rules])
            if p[:rules]
                if config[:ignore_global_rules]
                    rule_ids = JSON.parse(p[:rules])
                else
                    puts JSON.parse(p[:rules])
                    rule_ids += JSON.parse(p[:rules])
                end
            end
            rules = Rules.graph(:rule_types, :id => :rule_type_id)
                .where(:rules__id => rule_ids)
                .select(:rules__rule, :rule_types__name)

            Rails.logger.debug "performing task: #{rules}"
            CommitCollector.perform_async(p[:id], p[:name], p[:last_commit_time],
                config[:github_token], config[:crawl_frequency], rules)
        end
    end
end

re = RepoEnqueuer.new
re.perform
