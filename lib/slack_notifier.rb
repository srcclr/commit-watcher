require 'json'

class SlackNotifier
  def initialize(webhook, project_id, commit_hash, audit_result)
    project = Projects[id: project_id]
    @project_name = project.name
    @commit_hash = commit_hash
    @audit_result = JSON.pretty_generate(audit_result) || {}
    @webhook = webhook
  end

  def notify
    notifier = Slack::Notifier.new @webhook
    notifier.ping "Commit hash [#{@commit_hash}](https://#{@project_name}/commit/#{commit_hash}) of the project #{@project_name} has been detected to violate the following:\n#{@audit_result}\n"
  end
end