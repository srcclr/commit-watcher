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

class API::V1::RulesController < ApplicationController
  def index
    @rules = Rules
    render json: @rules
  end

  def show
    @rule = Rules[id: params[:id].to_i]
    render json: @rule
  end

  def create
    @rule = Rules.new(rule_params)
    begin
      @rule.save
      render json: { status: 'ok', message: 'rule created' }
    rescue Sequel::ValidationFailed, Sequel::DatabaseError => e
      render json: { status: 'error', message: e }
    end
  end

  def update
    @rule = Rules[id: params[:id].to_i]
    begin
      @rule.update(rule_params)
      render json: { status: 'ok', message: 'rule updated' }
    rescue Sequel::ValidationFailed, Sequel::DatabaseError => e
      render json: { status: 'error', message: e }
    end
  end

  def destroy
    @rule = Rules[id: params[:id].to_i]
    @rule.destroy
    render json: { status: 'ok', message: 'rule destroyed' }
  end

private

  def rule_params
    params.require(:name)
    params.require(:rule_type_id)
    params.require(:value)
    params.require(:description)
    params.permit(:name, :rule_type_id, :value, :description)
  end
end
