class API::V1::CommitsController < ApplicationController
  def index
    @commits = Commits
    render json: @commits
  end

  def show
    @commit = Commits[id: params[:id].to_i]
    render json: @commit
  end

  def wipe
    Commits.truncate
    render json: { status: 'ok', message: 'wiped commits' }
  end
end
