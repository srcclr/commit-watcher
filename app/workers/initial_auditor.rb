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

require_relative "#{Rails.root}/lib/audit_results_builder"
require_relative "#{Rails.root}/lib/git_repo"

class InitialAuditor
  include Sidekiq::Worker
  sidekiq_options queue: :initial_audits

  def perform(project_id, project_name, project_username, project_access_token, rules)
    Rails.logger.debug "Collecting commits for #{project_name} for the first time"
    repo = GitRepo.new(project_name, project_username, project_access_token)
    Rails.logger.debug "Collected #{repo.commits.size} commits from #{project_name}"

    start_time = Time.now
    rules = JSON.parse(rules, symbolize_names: true)
    builder = AuditResultsBuilder.new
    commits = []
    count = 0
    repo.diffs do |commit_hash, diff|
      count += 1
      commits << commit_hash

      Rails.logger.debug "Auditing (#{count}/#{repo.commits.size}) #{commit_hash[:sha]} for #{project_name}"
      results = builder.build(project_id, commit_hash, diff, rules)
      next unless results

      begin
        Commits.create(results)
      rescue Sequel::UniqueConstraintViolation
        Rails.logger.debug "Dropping duplicate commit: #{results}"
      end
    end
    repo.destroy
    end_time = Time.now
    Rails.logger.debug "Finished auditing #{project_name} in #{end_time - start_time} seconds"

    # Sometimes commits don't have all information
    # e.g. https://github.com/activerecord-hackery/meta_search/commit/f95e7e225242a42646d1ef51e3d71c917e8fc148
    # When processed locally, the commit is just:
    # {:sha=>"f95e7e225242a42646d1ef51e3d71c917e8fc148", :commit=>{:message=>"bla bla", :author=>{}, :committer=>{}}}
    time_strs = commits.collect { |c| c[:commit][:author][:date] }.compact
    last_commit_time = time_strs.collect { |s| Time.parse(s) }.max
    project = Projects[id: project_id]
    return unless project # project was deleted while this was auditing

    project.update(last_commit_time: last_commit_time)
  end
end
