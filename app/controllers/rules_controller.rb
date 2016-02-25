class RulesController < ApplicationController
  def index
    @rules = Rules
  end

  def edit
    id = params[:id].to_i
    @rule = Rules[:id => id]
  end

  def create
    @rule = Rules.create(create_rule_params)

    redirect_to action: 'index'
  end

  def update
    id = params[:id].to_i
    @rule = Rules[:id => id]

    begin
      @rule.update(update_rule_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationError
      render 'edit'
    end
  end

  def destroy
    id = params[:id].to_i
    @rule = Rules[:id => id]
    @rule.destroy

    redirect_to rules_path
  end

private

  def create_rule_params
    params.require(:rule).permit(:rule_type_id, :rule)
  end

  def update_rule_params
    params.require(:rule).permit(:rule_type_id, :rule)
  end
end
