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

require 'git_diff_parser'
require 'activesupport/json_encoder'

require_relative "#{Rails.root}/lib/audit_results_builder"
require_relative "#{Rails.root}/lib/github_api"

class CommitAuditor
  include Sidekiq::Worker
  sidekiq_options queue: :audit_commits

  def perform(project_id, commit, rules, github_token)
    commit = JSON.parse(commit, symbolize_names: true)
    rules = JSON.parse(rules, symbolize_names: true)
    diff = get_commit_diff(commit, rules, github_token)

    builder = AuditResultsBuilder.new
    record = builder.build(project_id, commit, rules, diff)
    return unless record

    begin
      Commits.insert(record)
    rescue Sequel::UniqueConstraintViolation
      Rails.logger.debug "Dropping duplicate commit: #{record}"
    end
  end

private

  def get_commit_diff(commit, rules, github_token)
    rule_type_ids = rules.collect { |e| e[:rule_type_id] }
    diff_rule_type_ids = RuleTypes.select { |k, v| v[:requires_diff] }.keys
    return if (rule_type_ids & diff_rule_type_ids).empty?

    #curl -H "Accept: application/vnd.github.diff" https://api.github.com/repos/CalebFenton/simplify/commits/d6dcaa7203e859037bfaa1222f85111feb3dbe93
    commit_url = commit[:url]
    headers = { 'Accept' => 'application/vnd.github.VERSION.diff' }
    diff_raw = GitHubAPI.request_page(commit_url, github_token, nil, headers)
    diff_raw.empty? ? nil : GitDiffParser.parse(diff_raw)
  end
end
