class API::V1::ConfigurationsController < ApplicationController
  def index
    @configurations = Configurations
    render json: @configurations
  end

  def update
    @configuration = Configurations[id: params[:id].to_i]
    begin
      @configuration.update(configuration_params)
      render json: { status: 'ok', message: 'configuration updated' }
    rescue Sequel::ValidationFailed, Sequel::DatabaseError => e
      render json: { status: 'error', message: e }
    end
  end

private

  def configuration_params
    params.require(:name)
    params.require(:audit_frequency)
    params.require(:github_token)
    params.permit(:name, :audit_frequency, :github_token)
  end
end
