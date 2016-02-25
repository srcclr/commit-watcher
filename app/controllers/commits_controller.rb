class CommitsController < ApplicationController
  def index
    @commits = Commits.graph(:projects, {id: :project_id}, {join_type: :inner} )
                .select_all(:commits)
                .select_append(:projects__name___project_name)
  end
end
