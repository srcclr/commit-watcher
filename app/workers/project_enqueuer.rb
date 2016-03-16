require_relative 'commit_collector'
require_relative '../models/configurations'
require_relative '../models/projects'

class ProjectEnqueuer
    include Sidekiq::Worker
    sidekiq_options queue: :enqueue_projects

    def perform
        projects = Projects.where { next_audit <= Time.now.to_i }
        return if projects.empty?
        config = Configurations[name: 'default']

        enqueue_projects(projects, config[:audit_frequency], config[:github_token])
    end

    def enqueue_projects(projects, audit_frequency, github_token)
        projects.each do |p|
            next unless p[:rule_sets]

            rules = get_rules(JSON.parse(p[:rule_sets]))
            last_commit_time = p[:last_commit_time] || Time.at(0)
            CommitCollector.perform_async(
                p[:id],
                p[:name],
                last_commit_time,
                audit_frequency,
                rules.to_json,
                github_token
            )
        end
    end

    def get_rules(rule_set_names)
        rule_sets = RuleSets.where(name: rule_set_names).to_hash
        rule_names = rule_sets.values.collect { |e| JSON.parse(e[:rules]) }.flatten.sort.uniq
        Rules.where(name: rule_names).select(:name, :rule_type_id, :value)
    end
end
