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

class RulesController < ApplicationController
  def index
    @rules = Rules
  end

  def edit
    @rule = Rules[id: params[:id].to_i]
  end

  def create
    @rule = Rules.new(rule_params)
    begin
      @rule.save
      redirect_to action: 'index'
    rescue Sequel::ValidationFailed
      render 'new'
    rescue Sequel::DatabaseError => e
      render 'new'
    end
  end

  def update
    @rule = Rules[id: params[:id].to_i]
    begin
      @rule.update(rule_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationFailed
      render 'edit'
    rescue Sequel::DatabaseError => e
      render 'edit'
    end
  end

  def destroy
    @rule = Rules[id: params[:id].to_i]
    @rule.destroy

    redirect_to rules_path
  end

private

  def rule_params
    params.require(:rule).permit(:name, :rule_type_id, :value, :description)
  end
end
