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

class CommitsController < ApplicationController
  helper_method :sort_column, :sort_direction

  def index
    @commits = Commits.join(:projects, id: :project_id)
        .select_all(:commits)
        .select_append(:projects__name)
        .order(order_expr)

    @commits = @commits.where(status_type_id: params[:status_type_id]) if valid_status_type?
    @commits = @commits.where(project_id: params[:project_id]) if valid_project_id?
    @commits = @commits.where(Sequel.like(:commit_hash, "#{params[:commit_hash]}%")) if valid_commit_hash?
    @commits = @commits.where(Sequel.like(:audit_results, "%#{params[:audit_results]}%")) if params[:audit_results]

    page = params[:page] ? params[:page].to_i : 1
    results_per_page = 25
    @commits = @commits.paginate(page, results_per_page)
  end

  def update
    @commit = Commits[id: params[:id].to_i]
    begin
      @commit.update(rule_params)
    rescue Sequel::ValidationFailed
      render 'index'
    rescue Sequel::DatabaseError => e
      render 'index'
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.js { }
    end
  end

  def show
    id = params[:id].to_i
    ds = Commits.join(:projects, id: :project_id)
        .select_all(:commits)
        .select_append(:projects__name)
        .where(commits__id: id)
    @commit = ds.first
  end

private

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def sort_column
    Commits.columns.include?(params[:order] && params[:order].to_sym) ? params[:order] : 'project_id'
  end

  def valid_status_type?
    StatusTypes.keys.map(&:to_s).include?(params[:status_type_id])
  end

  def valid_commit_hash?
    params[:commit_hash] && params[:commit_hash] =~ /\A[a-f0-9]+\z/i
  end

  def valid_project_id?
    params[:project_id] && params[:project_id] =~ /\A\d+\z/
  end

  def order_expr
    Sequel.send(sort_direction, sort_column.to_sym)
  end

  def rule_params
    params.require(:commit).permit(:status_type_id)
  end
end
