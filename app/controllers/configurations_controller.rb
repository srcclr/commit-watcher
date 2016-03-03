class ConfigurationsController < ApplicationController
  def index
    @configurations = Configurations
  end

  def edit
    @configuration = Configurations[id: params[:id].to_i]
  end

  def update
    @configuration = Configurations[id: params[:id].to_i]
    begin
      @configuration.update(configuration_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationFailed
      render 'edit'
    end
  end

private

  def configuration_params
    params.require(:configuration).permit(:name, :audit_frequency, :github_token)
  end
end
