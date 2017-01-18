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
require 'rugged'
require 'fileutils'

class GitRepo
  def initialize(project_name)
    @project_name = project_name
    @repo = nil
  end

  def commits
    #Rails.logger.debug "called commits for #{@project_name}"
    return @commits if @commits

    repo_local_path = make_temp_dir(@project_name)
    @repo ||= clone(repo_local_path)
    walker = Rugged::Walker.new(@repo)
    walker.push(@repo.head.target)
    @commits = walker.to_a
    #Rails.logger.debug "built walker for #{@project_name}, #{@commits.size}"
    # FileUtils.rm_rf(repo_local_path)
    @commits
  end

  def diffs
    commits
    @commits.each do |commit|
      #Rails.logger.debug "diffing #{commit.oid}"
      patch_s = nil
      if commit.parents.empty?
        patch = commit.diff.patch
      else
        patch = commit.parents.first.diff(commit).patch
      end

      commit_hash = build_commit_hash(commit)
      #Rails.logger.debug "parsing patch for #{commit.oid}"
      diff = patch.empty? ? nil : GitDiffParser.parse(
        patch.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      )
      #Rails.logger.debug "FINISHED parsing patch for #{commit.oid}"

      yield [commit_hash, diff]
    end
  end

private

  def make_temp_dir(project_name)
    Dir.mktmpdir(['cwatcher', @project_name.sub('/', '-')])
  end

  def clone(project_path)
    #Rails.logger.debug "getting clone of #{@project_name}"
    cmd = "git clone --no-checkout --quiet https://anon:anon@github.com/#{@project_name} #{project_path}"
    result = `#{cmd} 2>&1`
    fail result if $?.exitstatus != 0
    #Rails.logger.debug "done cloning #{@project_name}"

    Rugged::Repository.new(project_path)
  end

  def build_commit_hash(commit)
    # Make a hash that looks a bit like GitHub commit
    {
      sha: commit.oid,
      commit: {
        message: commit.message,
        author: {
          name: commit.author[:name],
          email: commit.author[:email],
          date: commit.author[:time].iso8601,
        },
        committer: {
          name: commit.committer[:name],
          email: commit.committer[:email],
          date: commit.committer[:time].iso8601,
        },
      },
    }
  end
end
