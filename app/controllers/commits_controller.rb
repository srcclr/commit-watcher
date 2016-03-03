class CommitsController < ApplicationController
  def index
    @commits = Commits
  end

  def show
    @commit = Commits[id: params[:id].to_i]
  end
end
