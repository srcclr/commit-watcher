class RuleTypesController < ApplicationController
  def index
    @rule_types = RuleTypes
  end

  def edit
    id = params[:id].to_i
    @rule_type = RuleTypes[:id => id]
  end

  def create
    @rule_type = RuleTypes.create(create_rule_type_params)

    redirect_to action: 'index'
  end

  def update
    id = params[:id].to_i
    @rule_type = RuleTypes[:id => id]

    begin
      @rule_type.update(update_rule_type_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationError
      render 'edit'
    end
  end

  def destroy
    id = params[:id].to_i
    @rule_type = RuleTypes[:id => id]
    @rule_type.destroy

    redirect_to rule_types_path
  end

private

  def create_rule_type_params
    params.require(:rule_type).permit(:name)
  end

  def update_rule_type_params
    params.require(:rule_type).permit(:name)
  end
end
