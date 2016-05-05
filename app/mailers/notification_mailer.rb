require 'json'

class NotificationMailer < ApplicationMailer
  default from: 'notifications@commit-watcher.com'
  layout 'mailer'

  def notification(target, project_id, commit_hash, audit_result)
    project = Projects[id: project_id]

    @project_name = project.name
    @commit_hash = commit_hash
    @audit_result = audit_result

    mail(to: target, subject: "Audit Notification for #{@project_name}")
  end
end
