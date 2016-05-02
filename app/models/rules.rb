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

require_relative "#{Rails.root}/lib/rules/expression_rule"

class Rules < Sequel::Model
  plugin :validation_helpers

  def validate
    super

    validates_presence [:name, :rule_type_id, :value]
    validates_unique :name
    validates_min_length 3, :name, message: -> (s) { "of rule must be more than #{s} characters" }
    validates_format /[A-Za-z0-9\-\._]+/,
        :name,
        message: 'name must only include letters, numbers, and "-", ".", "_"'

    validates_includes RuleTypes.keys, :rule_type_id

    expression_id = RuleTypes.select { |_, v| v[:name] == 'expression' }.keys.first
    if rule_type_id == expression_id
      dummy = value.gsub(/[A-Za-z0-9\-\._]+/, 'true')
      begin
        Boolean.parse(dummy)

        exp = ExpressionRule.new(value)
        exp.rule_names.each do |exp_rule_name|
          next if Rules[name: exp_rule_name]
          errors.add(:value, "referenced rule does not exist: #{exp_rule_name}")
        end
      rescue Citrus::ParseError => e
        errors.add(:value, "invalid boolean expression: #{value}")
      end
    else
      begin
        Regexp.new(value)
      rescue RegexpError => e
        errors.add(:value, "invalid value pattern: #{e}")
      end
    end
  end
end
