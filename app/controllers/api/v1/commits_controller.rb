Sequel.extension :pagination

class API::V1::CommitsController < ApplicationController
  def index
    page_no = (params[:page] || 1).to_i
    page_size = (params[:size] || 100).to_i

    begin
      content = Commits.dataset.paginate(page_no, page_size)
      @commits = { page: page_no, page_size: page_size }
      @commits[:next_page] = content.next_page if content.next_page
      @commits[:content] = content
      render json: @commits
    rescue Sequel::Error => e
      render json: { status: 'error', message: e.to_s }
    end
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
