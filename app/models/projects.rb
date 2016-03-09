require 'json'

class Projects < Sequel::Model
  plugin :validation_helpers

  def validate
    super

    validates_presence [:name, :rule_sets]
    validates_unique :name
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
