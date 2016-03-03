require 'json'

class RuleSets < Sequel::Model
  plugin :validation_helpers

  def validate
    super
    validates_presence [:name, :rules]

    validates_unique :name
    validates_min_length 3, :name, message: -> (s) { "must be more than #{s} characters" }

    rule_names = nil
    begin
        rule_names = JSON.parse(rules)

        errors.add(:rules, 'must include at least one rule') if rule_names.empty?

        all_rule_names = Rules.select(:name).collect { |r| r[:name] }
        rule_names.each do |rule_name|
            next if all_rule_names.include?(rule_name)
            errors.add(:rules, 'referenced rule #{rule_name} does not exist')
        end
    rescue JSON::ParserError => e
        errors.add(:rules, 'invalid JSON value #{rules}')
    end
  end
end
