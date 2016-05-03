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
  def index
    @commits = Commits.join(:projects, id: :project_id)
        .select_all(:commits)
        .select_append(:projects__name)

    page = params[:page] ? params[:page].to_i : 1
    results_per_page = 25
    @commits = @commits.paginate(page, results_per_page)
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
