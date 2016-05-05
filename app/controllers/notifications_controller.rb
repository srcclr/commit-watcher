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

class NotificationsController < ApplicationController
  def index
    @notifications = Notifications
  end

  def edit
    @notification = Notifications[id: params[:id].to_i]
  end

  def create
    @notification = Notifications.new(notification_params)
    begin
      @notification.save
      redirect_to action: 'index'
    rescue Sequel::ValidationFailed
      render 'new'
    rescue Sequel::DatabaseError => e
      render 'new'
    end
  end

  def update
    @notification = Notifications[id: params[:id].to_i]
    begin
      @notification.update(notification_params)
      redirect_to action: 'index'
    rescue Sequel::ValidationFailed
      render 'edit'
    rescue Sequel::DatabaseError => e
      render 'edit'
    end
  end

  def destroy
    @notification = notifications[id: params[:id].to_i]
    @notification.destroy

    redirect_to notifications_path
  end

private

  def notification_params
    params.require(:notification).permit(:name, :notification_type_id, :target)
  end
end
