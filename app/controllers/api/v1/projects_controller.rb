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

class API::V1::ProjectsController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    @projects = Projects
    render json: @projects
  end

  def show
    @project = Projects[id: params[:id].to_i]
    render json: @project
  end

  def create
    @project = Projects.new(create_project_params)
    begin
      @project.save
      render json: { status: 'ok', message: 'project created' }
    rescue Sequel::ValidationFailed, Sequel::DatabaseError => e
      render json: { status: 'error', message: e }
    end
  end

  def update
    @project = Projects[id: params[:id].to_i]
    begin
      @project.update(update_project_params)
      render json: { status: 'ok', message: 'project updated' }
    rescue Sequel::ValidationFailed, Sequel::DatabaseError => e
      render json: { status: 'error', message: e }
    end
  end

  def destroy
    @project = Projects[id: params[:id].to_i]
    @project.destroy
    render json: { status: 'ok', message: 'project destroyed' }
  end

private

  def create_project_params
    params.require(:name)
    params.require(:rule_sets)
    params.permit(:name, :rule_sets)
  end

  def update_project_params
    params.require(:name)
    params.require(:rule_sets)
    params.require(:next_audit)
    params.require(:last_commit_time)
    params.permit(:name, :rule_sets, :next_audit, :last_commit_time)
  end
end
