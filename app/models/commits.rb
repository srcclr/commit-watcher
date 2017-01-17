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

require 'json'
require_relative "#{Rails.root}/app/mailers/notification_mailer"
require_relative "#{Rails.root}/lib/slack_notifier"

class Commits < Sequel::Model
  def after_create
    super

    audit_results = JSON.parse(self.audit_results, symbolize_names: true)
    audit_results.each do |audit_result|
        next unless audit_result.is_a?(Hash) && audit_result.has_key?(:notification_id)

        notification_id = audit_result[:notification_id]
        next unless notification_id

        notification = Notifications[id: notification_id]

        if rule[:notification_id] == 0
          NotificationMailer.notification(notification.target, self.project_id, self.commit_hash, audit_result).deliver_now
        elsif rule[:notification_id] == 1
          SlackNotifier.new(notification.target, self.project_id, commit_hash, audit_result).notify
        end
    end
  end
end
