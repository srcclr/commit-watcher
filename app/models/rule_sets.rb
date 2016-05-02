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

class RuleSets < Sequel::Model
  plugin :validation_helpers

  def validate
    super

    validates_presence [:name, :rules]
    validates_unique :name
    validates_min_length 3, :name, message: -> (s) { "of rule set must be more than #{s} characters" }

    begin
        rule_names = JSON.parse(rules)
        errors.add(:rules, 'must include at least one rule') if rule_names.empty?

        all_rule_names = Rules.select(:name).collect { |r| r[:name] }
        rule_names.each do |rule_name|
            next if all_rule_names.include?(rule_name)
            errors.add(:rules, "referenced rule does not exist: #{rule_name}")
        end
    rescue JSON::ParserError => e
        errors.add(:rules, "invalid JSON value: #{rules} - #{e}")
    end
  end
end
