=begin
Copyright 2016 SourceClear Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

Sequel.extension :pagination

class API::V1::CommitsController < ApplicationController
  def index
    page_no = (params[:page] || 1).to_i
    page_size = (params[:size] || 100).to_i

    begin
      if params[:project_id]
        content = Commits.where(project_id: params[:project_id].to_i).paginate(page_no, page_size)
      else
        content = Commits.dataset.paginate(page_no, page_size)
      end
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
