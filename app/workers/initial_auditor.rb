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

class InitialAuditor
  include Sidekiq::Worker
  sidekiq_options queue: :initial_audits

  def perform(project_id, project_name, rules)
    Rails.logger.debug "Collecting commits for #{project_name} for the first time"

    rules = JSON.parse(rules, symbolize_names: true)
    tmpdir = Dir.mktmpdir(['cwatcher', project_name.sub('/', '-')])
    commits = []
    begin
      git = clone(project_name, tmpdir)
      builder = AuditResultsBuilder.new
      # Log helpfully forces a limit which defaults to 30.
      git_commits = git.log(100000000)
      Rails.logger.debug "Collected #{git_commits.size} commits from #{project_name}"
      count = 0
      git_commits.each do |c|
        count += 1
        Rails.logger.debug "Auditing (#{count}/#{git_commits.size}) #{c.sha} for #{project_name}"

        diff = nil
        begin
          diff = get_commit_diff(git, c)
        rescue Git::GitExecuteError => e
          Rails.logger.warn e.backtrace.join("\n")
          # Git parsing gem has trouble with a repo every now and then
          # Skip this commit
          next
        end

        commit = build_commit_hash(c)
        commits << commit
        record = builder.build(project_id, commit, rules, diff)
        next unless record

        begin
          Commits.insert(record)
        rescue Sequel::UniqueConstraintViolation
          Rails.logger.debug "Dropping duplicate commit: #{record}"
        end
      end
    ensure
      FileUtils.remove_entry_secure(tmpdir) if File.exist?(tmpdir)
    end

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

private

  def clone(project_name, dir)
    cmd = "git clone --no-checkout --quiet https://anon:anon@github.com/#{project_name} #{dir}"
    result = `#{cmd} 2>&1`
    fail result if $?.exitstatus != 0

    Git.open(dir)
  end

  def get_commit_diff(git, commit)
    diff_raw = nil
    if commit.parent
      diff_raw = git.diff(commit, commit.parent).to_s
    else
      diff_raw = git.diff(commit).to_s
    end
    diff_raw.empty? ? nil : GitDiffParser.parse(
      diff_raw.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    )
  end

  def build_commit_hash(git_commit)
    commit_json = JSON.parse(git_commit.to_json, symbolize_names: true)

    # Make a hash that looks a bit like GitHub commit
    {
      sha: commit_json[:sha],
      commit: {
        message: commit_json[:message],
        author: commit_json[:author],
        committer: commit_json[:committer],
      },
    }
  end
end
