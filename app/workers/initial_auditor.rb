require 'git_diff_parser'
require 'activesupport/json_encoder'

require_relative "#{Rails.root}/lib/audit_results_builder"
require_relative "#{Rails.root}/lib/github_api"

class InitialAuditor
  include Sidekiq::Worker
  sidekiq_options queue: :initial_audits

  def perform(project_id, project_name, rules, github_token)
    Rails.logger.debug "Collecting commits for #{project_name} for the first time"

    rules = JSON.parse(rules, symbolize_names: true)
    tmpdir = nil
    commits = []
    begin
      git, tmpdir = clone(project_name)
      builder = AuditResultsBuilder.new
      git_commits = git.log
      Rails.logger.debug "Collected #{git_commits.size} commits from #{project_name}"
      git_commits.each do |c|
        diff = get_commit_diff(git, c)
        commit_json = JSON.parse(c.to_json, symbolize_names: true)
        commit = build_commit_hash(commit_json)
        commits << commit

        Rails.logger.debug "Auditing #{c.sha} for #{project_name}"
        record = builder.build(project_id, commit, rules, diff)
        next unless record

        begin
          Commits.insert(record)
        rescue Sequel::UniqueConstraintViolation
          Rails.logger.debug "Dropping duplicate commit: #{record}"
        end
      end
    ensure
      FileUtils.remove_entry_secure(tmpdir)
    end

    last_commit_time = commits.collect { |c| Time.parse(c[:commit][:author][:date]) }.max
    Projects[id: project_id].update(last_commit_time: last_commit_time)
  end

private

  def clone(project_name)
    dir = Dir.mktmpdir(['cwatcher', project_name.sub('/', '-')])
    cmd = "git clone https://github.com/#{project_name} #{dir}"
    `#{cmd}`
    [Git.open(dir), dir]
  end

  def get_commit_diff(git, commit)
    diff_raw = git.diff(commit).to_s
    diff_raw.empty? ? nil : GitDiffParser.parse(diff_raw)
  end

  def build_commit_hash(commit_json)
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
