require_relative 'commit_auditor'
require_relative "#{Rails.root}/lib/github_api"

class CommitCollector
    include Sidekiq::Worker
    sidekiq_options :queue => :collect_commits

    COMMITS_URL = 'https://api.github.com/repos/%s/commits'

    def perform(project_id, project_name, last_commit_time, audit_frequency, rules, github_token)
        # Set next audit immediately to avoid re-enqueueing.
        next_audit = Time.now.to_i + audit_frequency
        Projects[:id => project_id].update(:next_audit => next_audit)

        Rails.logger.debug "Collecting commits for #{project_name}"
        last_commit_time = Time.parse(last_commit_time)
        commits = collect_commits(project_name, last_commit_time, github_token)
        Rails.logger.debug "Collected #{commits.size} commits from #{project_name}"
        return if commits.size == 0

        commits.each do |c|
            CommitAuditor.perform_async(project_id, c.to_json, rules, github_token)
        end

        last_commit_time = commits.collect { |e| Time.parse(e['commit']['author']['date']) }.max
        Projects[:id => project_id].update(:last_commit_time => last_commit_time)
    end

    def collect_commits(project_name, last_commit_time, github_token)
        uri = COMMITS_URL % project_name
        since_time = last_commit_time + 1
        params = { since: since_time.iso8601 }
        response = GitHubAPI.request_json(uri, github_token, params)
        response
    end
end
