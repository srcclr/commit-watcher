class CommitsController < ApplicationController
  def index
    @commits = Commits
  end

  def show
    @commit = Commits[id: id]
  end
end
