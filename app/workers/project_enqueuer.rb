require_relative 'commit_collector'
require_relative 'initial_auditor'
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

      # Update next_audit immediately to avoid re-enqueueing.
      next_audit = Time.now.to_i + audit_frequency
      Projects[id: p[:id]].update(next_audit: next_audit)

      rules = get_rules(JSON.parse(p[:rule_sets]))
      last_commit_time = p[:last_commit_time] || Time.at(0)

      if last_commit_time == Time.at(0)
        # First time a project is audited, clone it locally since it
        # may be huge, and we don't want to hit our GitHub API request
        # limit too hard.
        InitialAuditor.perform_async(
          p[:id],
          p[:name],
          rules.to_json,
          github_token
        )
      else
        CommitCollector.perform_async(
          p[:id],
          p[:name],
          last_commit_time,
          rules.to_json,
          github_token
        )
      end
    end
  end

  def get_rules(rule_set_names)
    rule_sets = RuleSets.where(name: rule_set_names).to_hash
    rule_names = rule_sets.values.collect { |e| JSON.parse(e[:rules]) }.flatten.sort.uniq
    Rules.where(name: rule_names).select(:name, :rule_type_id, :value)
  end
end
