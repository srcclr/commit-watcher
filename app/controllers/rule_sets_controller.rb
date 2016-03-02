class RuleSetsController < ApplicationController
  def index
    @rule_sets = RuleSets
  end

  def edit
    @rule_set = RuleSets[id: params[:id].to_i]
  end

  def create
    @rule_set = RuleSets.create(rule_set_params)

    redirect_to action: 'index'
  end

  def update
    @rule_set = RuleSets[id: params[:id].to_i]

    begin
      @rule_set.update(rule_set_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationError
      render 'edit'
    end
  end

  def destroy
    @rule_set = Rules[id: params[:id].to_i]
    @rule_set.destroy

    redirect_to rule_set_path
  end

private

  def rule_set_params
    params.require(:rule_set).permit(:name, :rules, :description)
  end
end
