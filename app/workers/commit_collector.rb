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

require_relative 'commit_auditor'
require_relative "#{Rails.root}/lib/github_api"

class CommitCollector
  include Sidekiq::Worker
  sidekiq_options queue: :collect_commits

  COMMITS_URL = 'https://api.github.com/repos/%s/commits'.freeze

  def perform(project_id, project_name, project_username, project_access_token, last_commit_time, rules, github_token)
    last_commit_time = Time.parse(last_commit_time)
    Rails.logger.debug "Collecting commits for #{project_name} since #{last_commit_time}"

    commits = collect_commits(project_name, project_username, project_access_token, last_commit_time, github_token)
    Rails.logger.debug "Collected #{commits.size} commits from #{project_name}"
    return if commits.size == 0

    commits.each do |c|
      CommitAuditor.perform_async(project_id, project_username, project_access_token, c.to_json, rules, github_token)
    end

    last_commit_time = commits.collect { |c| Time.parse(c[:commit][:author][:date]) }.max
    Projects[id: project_id].update(last_commit_time: last_commit_time)
  end

  def collect_commits(project_name, project_username, project_access_token, last_commit_time, github_token)
    gh = GitHubAPI.new(github_token, project_username, project_access_token)
    gh.get_commits(project_name, last_commit_time)
  end
end
