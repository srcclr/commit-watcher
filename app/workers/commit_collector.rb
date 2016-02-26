require_relative 'auditor'
require_relative '../../lib/github_api'

class CommitCollector
    include Sidekiq::Worker
    sidekiq_options :queue => :collect_commits

    COMMITS_URL = 'https://api.github.com/repos/%s/commits'

    def perform(project_id, repo_name, last_commit_time, audit_frequency, rules, github_token)
        # Set next audit now even though there may be an error because sometimes the audit
        # takes longer than the enquerer frequency and we want to avoid double queueing.
        next_audit = Time.now.to_i + audit_frequency
        Projects[:id => project_id].update(:next_audit => next_audit)

        Rails.logger.debug "Collecting commits for #{repo_name}"
        last_commit_time = Time.parse(last_commit_time)
        commits = collect_commits(repo_name, last_commit_time, github_token)
        Rails.logger.debug "Collected #{commits.size} commits from #{repo_name}"
        return if commits.size == 0

        commits.each do |c|
            Auditor.perform_async(project_id, c.to_json, rules, github_token)
        end

        last_commit_time = commits.collect { |e| Time.parse(e['commit']['author']['date']) }.max
        Projects[:id => project_id].update(:last_commit_time => last_commit_time)
    end

    def collect_commits(repo_name, last_commit_time, github_token)
        uri = COMMITS_URL % repo_name
        since_time = last_commit_time + 1
        params = { since: since_time.iso8601 }
        response = GitHubAPI.request_json(uri, github_token, params)
        response
    end

end
