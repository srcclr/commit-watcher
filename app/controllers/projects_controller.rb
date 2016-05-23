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

require_relative "#{Rails.root}/lib/github_api"

class ProjectsController < ApplicationController
  def index
    @projects = Projects
  end

  def edit
    @project = Projects[id: params[:id].to_i]
  end

  def create
    params = create_project_params
    begin
      if params[:name].include?('/')
        @project = import_project(params[:name], params[:rule_sets])
      else
        @project = import_user(params[:name], params[:rule_sets])
      end

      redirect_to action: 'index'
    rescue Sequel::ValidationFailed
      render 'new'
    rescue Sequel::DatabaseError => e
      render 'new'
    end
  end

  def update
    @project = Projects[id: params[:id].to_i]
    begin
      @project.update(update_project_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationFailed
      render 'edit'
    rescue Sequel::DatabaseError => e
      render 'edit'
    end
  end

  def destroy
    @project = Projects[id: params[:id].to_i]
    @project.destroy

    redirect_to projects_path
  end

private

  def import_user(username, rule_sets)
    github_token = Configurations.first.github_token
    gh = GitHubAPI.new(github_token)
    repo_names = gh.get_repo_names(username)
    repo_names.each do |repo_name|
      import_project("#{username}/#{repo_name}", rule_sets)
    end
  end

  def import_project(name, rule_sets)
    project = Projects.new({ name: name, rule_sets: rule_sets })
    project.save
    project
  end

  def create_project_params
    params.require(:project).permit(:name, :rule_sets)
  end

  def update_project_params
    params.require(:project).permit(:name, :rule_sets, :next_audit, :last_commit_time)
  end
end
