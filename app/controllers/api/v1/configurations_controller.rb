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
