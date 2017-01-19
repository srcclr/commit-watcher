require 'json'

class SlackNotifier
  def initialize(webhook, project_id, commit_hash, audit_result)
    project = Projects[id: project_id]
    @project_name = project.name
    @commit_hash = commit_hash
    @audit_result = audit_result
    @webhook = webhook
  end

  def notify
    notifier = Slack::Notifier.new @webhook
    notifier.ping "Commit hash [#{@commit_hash}](https://#{@project_name}/commit/#{commit_hash}) of the project #{@project_name} has been detected to violate the following:\n#{rule_name}\n"
  end

  private

  def rule_name
    return @audit_result['rule_name'] if @audit_result.key?('rule_name')
    'Unknown rule/Improper audit result object returned.'
  end
end