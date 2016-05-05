=begin
Copyright 2016 SourceClear Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require_relative 'commit_collector'
require_relative 'initial_auditor'
require_relative '../models/configurations'
require_relative '../models/projects'

class ProjectEnqueuer
  include Sidekiq::Worker
  sidekiq_options queue: :enqueue_projects

  def perform
    projects = Projects.where {
      (next_audit <= Time.now.to_i) &
      (rule_sets !~ nil) &
      (rule_sets !~ '[]') &
      ((last_commit_time =~ nil) |
      (last_commit_time >= Time.at(0)))
    }
    return if projects.empty?
    config = Configurations[name: 'default']

    enqueue_projects(projects, config[:audit_frequency], config[:github_token])
  end

  private

  def enqueue_projects(projects, audit_frequency, github_token)
    projects.each do |project|
      rule_sets = get_rules(JSON.parse(project[:rule_sets]))

      # Update next_audit immediately to avoid re-enqueueing.
      next_audit = Time.now.to_i + audit_frequency
      project.update(next_audit: next_audit)

      last_commit_time = project[:last_commit_time] || Time.at(0)
      if last_commit_time == Time.at(0)
        # Ensure this project isn't initially audited again until it's finished
        project.update(last_commit_time: Time.at(-1))

        # First time a project is audited, clone it locally to avoid
        # using up our GitHub API limits.
        InitialAuditor.perform_async(
          project[:id],
          project[:name],
          rule_sets.to_json
        )
      else
        CommitCollector.perform_async(
          project[:id],
          project[:name],
          last_commit_time,
          rule_sets.to_json,
          github_token
        )
      end
    end
  end

  def get_rules(rule_set_names)
    rule_sets = RuleSets.where(name: rule_set_names).to_hash
    rule_names = rule_sets.values.collect { |s| JSON.parse(s[:rules]) }.flatten.sort.uniq
    Rules.where(name: rule_names).select(:id, :name, :rule_type_id, :value, :notification_id)
  end
end
