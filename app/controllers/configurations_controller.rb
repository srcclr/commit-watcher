require 'sequel'

class ConfigurationsController < ApplicationController
  def index
    @configurations = Configurations
  end

  def edit
    id = params[:id].to_i
    @configuration = Configurations[:id => id]
  end

  def update
    id = params[:id].to_i
    @configuration = Configurations[:id => id]

    begin
      @configuration.update(update_configuration_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationError
      render 'edit'
    end
  end

private

  def update_configuration_params
    params.require(:configuration).permit(:audit_frequency, :global_rules, :github_token)
  end
end
