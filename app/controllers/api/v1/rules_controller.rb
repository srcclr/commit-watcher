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
