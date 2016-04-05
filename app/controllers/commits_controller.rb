class CommitsController < ApplicationController
  def index
    @commits = Commits.join(:projects, id: :project_id)
        .select_all(:commits)
        .select_append(:projects__name)
  end

  def show
    id = params[:id].to_i
    ds = Commits.join(:projects, id: :project_id)
        .select_all(:commits)
        .select_append(:projects__name)
        .where(commits__id: id)
    @commit = ds.first
  end
end
