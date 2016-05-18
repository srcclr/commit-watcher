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

class GitRepoOld
  def initialize(project_name)
    @project_name = project_name
    @repo = nil
  end

  def commits
    return @commits if @commits

    @repo ||= clone

    # Log helpfully forces a limit which defaults to 30.
    @commits = @repo.log(100000000).to_a
    @commits
  end

  def diffs
    commits
    @commits.each do |commit|
      commit_hash = build_commit_hash(commit)
      diff = nil
      begin
        diff = get_commit_diff(commit)
      rescue Git::GitExecuteError => e
        Rails.logger.warn e.backtrace * "\n"
        # Git parsing gem has trouble with a repo every now and then
        # Skip this commit
        next
      end

      yield [commit_hash, diff]
    end
  end

private

  def clone
    path = Dir.mktmpdir(['cwatcher', @project_name.sub('/', '-')])
    cmd = "git clone --no-checkout --quiet https://anon:anon@github.com/#{@project_name} #{path}"
    result = `#{cmd} 2>&1`
    fail result if $?.exitstatus != 0

    Git.open(path)
  end

  def get_commit_diff(commit)
    diff_raw = nil
    if commit.parent
      diff_raw = @repo.diff(commit, commit.parent).to_s
    else
      diff_raw = @repo.diff(commit).to_s
    end
    diff_raw.empty? ? nil : GitDiffParser.parse(
      diff_raw.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    )
  end

  def build_commit_hash(commit)
    # Make a hash that looks a bit like GitHub commit
    commit_json = JSON.parse(commit.to_json, symbolize_names: true)
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
