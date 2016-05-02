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

class Projects < Sequel::Model
  plugin :validation_helpers

  def validate
    super

    validates_presence [:name, :rule_sets]
    validates_unique :name
    validates_format %r|\A[a-z\d][\w\-]{0,38}/[\w\-]{0,60}|i, :name
    validates_min_length 3, :name, message: -> (s) { "of project must be more than #{s} characters" }

    begin
        rule_set_names = JSON.parse(rule_sets)

        # Allow projects to be 'disabled' by emptying rule sets
        #errors.add(:rule_sets, 'must include at least one rule set') if rule_set_names.empty?

        all_sets_names = RuleSets.select(:name).collect { |r| r[:name] }
        rule_set_names.each do |set_name|
            next if all_sets_names.include?(set_name)
            errors.add(:rule_sets, "referenced rule set does not exist: #{set_name}")
        end
    rescue JSON::ParserError => e
        errors.add(:rule_sets, "invalid JSON value: #{rule_sets} - #{e}")
    end
  end
end
