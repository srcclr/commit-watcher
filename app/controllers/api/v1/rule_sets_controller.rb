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
    params.require(:rule_set).permit(:name, :rules, :description)
  end
end
