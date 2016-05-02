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

class API::V1::RuleSetsController < ApplicationController
  def index
    @rule_sets = RuleSets
    render json: @rule_sets
  end

  def show
    @rule_set = RuleSets[id: params[:id].to_i]
    render json: @rule_set
  end

  def create
    @rule_set = RuleSets.new(rule_set_params)
    begin
      @rule_set.save
      render json: { status: 'ok', message: 'rule set created' }
    rescue Sequel::ValidationFailed, Sequel::DatabaseError => e
      render json: { status: 'error', message: e }
    end
  end

  def update
    @rule_set = RuleSets[id: params[:id].to_i]
    begin
      @rule_set.update(rule_set_params)
      render json: { status: 'ok', message: 'rule set updated' }
    rescue Sequel::ValidationFailed, Sequel::DatabaseError => e
      render json: { status: 'error', message: e }
   end
  end

  def destroy
    @rule_set = RuleSets[id: params[:id].to_i]
    @rule_set.destroy
    render json: { status: 'ok', message: 'rule set destroyed' }
  end

private

  def rule_set_params
    params.require(:name)
    params.require(:rules)
    params.require(:description)
    params.permit(:name, :rules, :description)
  end
end
