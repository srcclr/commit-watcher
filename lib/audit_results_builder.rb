require 'json'
require 'time'
require_relative "#{Rails.root}/lib/rules/rule_auditor"

class AuditResultsBuilder
    def build(project_id, commit, rules, diff)
        audit_results = []
        rules.each do |r|
            audit_result = RuleAuditor.audit(
                commit,
                r[:rule_type_id],
                r[:value],
                diff
            )
            next unless audit_result

            audit_results << {
                rule_id: r[:id],
                rule_name: r[:name],
                rule_type_id: r[:rule_type_id],
                rule_value: r[:value],
                notification_id: r[:notification_id],
                audit_result: audit_result,
            }
        end
        return if audit_results.empty?

        {
            project_id: project_id,
            commit_hash: commit[:sha],
            commit_date: Time.iso8601(commit[:commit][:author][:date]),
            audit_results: audit_results.to_json,
        }
    end
end
