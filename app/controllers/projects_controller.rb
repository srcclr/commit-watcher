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

class ProjectsController < ApplicationController
  def index
    @projects = Projects
  end

  def edit
    @project = Projects[id: params[:id].to_i]
  end

  def create
    @project = Projects.new(create_project_params)
    begin
      @project.save
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

  def create_project_params
    params.require(:project).permit(:name, :rule_sets)
  end

  def update_project_params
    params.require(:project).permit(:name, :rule_sets, :next_audit, :last_commit_time)
  end
end
