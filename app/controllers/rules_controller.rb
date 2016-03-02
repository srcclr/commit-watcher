class RulesController < ApplicationController
  def index
    @rules = Rules
  end

  def edit
    @rule = Rules[id: params[:id].to_i]
  end

  def create
    @rule = Rules.create(rule_params)

    redirect_to action: 'index'
  end

  def update
    @rule = Rules[id: params[:id].to_i]

    begin
      @rule.update(rule_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationError
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
