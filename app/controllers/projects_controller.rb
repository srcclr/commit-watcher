class ProjectsController < ApplicationController
  def index
    @projects = Projects
  end

  def edit
    @project = Projects[id: params[:id].to_i]
  end

  def create
    @project = Projects.create(create_project_params)

    redirect_to action: 'index'
  end

  def update
    @project = Projects[id: params[:id].to_i]
    @project.update(update_project_params)
    redirect_to action: 'index'
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
