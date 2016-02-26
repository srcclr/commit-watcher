class CommitsController < ApplicationController
  def index
    @commits = Commits.graph(:projects, {id: :project_id}, {join_type: :inner} )
                .select_all(:commits)
                .select_append(:projects__name___project_name)
  end

  def show
    id = params[:id].to_i
    @commit = Commits.graph(:projects, {id: :project_id}, {join_type: :inner} )
                .where(commits__id: id)
                .select_all(:commits)
                .select_append(:projects__name___project_name).first
  end

end
