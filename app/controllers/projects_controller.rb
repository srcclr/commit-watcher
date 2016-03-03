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
    end
  end

  def update
    @project = Projects[id: params[:id].to_i]
    begin
      @project.update(update_project_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationFailed
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
