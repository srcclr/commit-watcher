require 'git_diff_parser'
require 'activesupport/json_encoder'

require_relative "#{Rails.root}/lib/github_api"
require_relative "#{Rails.root}/lib/rules/rule_auditor"

class Auditor
    include Sidekiq::Worker
    sidekiq_options :queue => :audit_commits

    def perform(project_id, commit, rules, github_token)
        commit = JSON.parse(commit, symbolize_names: true)
        rules = JSON.parse(rules, symbolize_names: true)
        diff = get_commit_diff(commit, rules, github_token)

        audit_results = []
        rules.each do |r|
            audit_result = RuleAuditor.audit(
                commit,
                r[:rule_type_id],
                r[:value],
                diff
            )
            next unless audit_result

            audit_results << {
                rule_name: r[:name],
                rule_type_id: r[:rule_type_id],
                rule_value: r[:value],
                audit_result: audit_result,
            }
        end
        return if audit_results.empty?

        record = {
            project_id: project_id,
            commit_hash: commit[:sha],
            commit_date: Time.iso8601(commit[:commit][:author][:date]),
            audit_results: audit_results.to_json,
        }

        Commits.insert(record)
    end

private

    def get_commit_diff(commit, rules, github_token)
        rule_type_ids = rules.collect { |e| e[:rule_type_id] }
        diff_rule_type_ids = RuleTypes.select { |k, v| v['requires_diff'] }.keys
        return if (rule_type_ids & diff_rule_type_ids).empty?

        #curl -H "Accept: application/vnd.github.diff" https://api.github.com/repos/CalebFenton/simplify/commits/d6dcaa7203e859037bfaa1222f85111feb3dbe93
        commit_url = commit[:url]
        headers = { 'Accept' => 'application/vnd.github.VERSION.diff' }
        diff_raw = GitHubAPI.request_page(commit_url, github_token, nil, headers)
        diff_raw.empty? ? nil : GitDiffParser.parse(diff_raw)
    end
end
