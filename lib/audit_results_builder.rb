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
require 'time'
require_relative "#{Rails.root}/lib/rules/rule_auditor"

class AuditResultsBuilder
  def initialize
    @all_rules = Rules.collect { |r| r.to_hash }
  end

  def build(project_id, commit, diff, rules)
    audit_results = []
    auditor = RuleAuditor.new(@all_rules)
    rules.each do |r|
      value2 = r[:value2] || ''
      audit_result = auditor.audit(
        commit,
        r[:rule_type_id],
        r[:value],
        diff,
        value2
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
