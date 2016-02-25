
class ProjectsController < ApplicationController
  def index
    @projects = Projects
  end

  def show
    id = params[:id].to_i
    @project = Projects[:id => id]
  end

  def edit
    id = params[:id].to_i
    @project = Projects[:id => id]
  end

  def create
    @project = Projects.create(create_project_params)

    redirect_to action: 'index'
  end

  def update
    id = params[:id].to_i
    @project = Projects[:id => id]

    begin
      @project.update(update_project_params)
      redirect_to action: 'show', id: id
    rescue Sequel::ValidationError
      render 'edit'
    end
  end

  def destroy
    id = params[:id].to_i
    @project = Projects[:id => id]
    @project.destroy

    redirect_to projects_path
  end

private

  def create_project_params
    params.require(:project).permit(:name, :rules, :ignore_global_rules)
  end

  def update_project_params
    params.require(:project).permit(:name, :rules, :ignore_global_rules, :next_audit, :last_commit_time)
  end
end
