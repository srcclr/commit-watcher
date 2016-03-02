require 'Citrus'

class ExpressionRule

    Citrus.load "#{Rails.root}/lib/rules/expression_rule"

    def initialize(expression)
        @expression = expression
        @evaluated_expression = expression
        @rules = parse_rules
    end

    def evaluate(commit, diff)
        results = []
        @rules.each do |rule|
            result = evaluate_rule(rule, commit, diff)
            update_expression(rule[:name], !result.nil?)
            results << result if result
        end

        m = Boolean.parse(@evaluated_expression)
        m ? results : nil
    end

private

    def update_expression(rule_name, bool_value)
        @evaluated_expression.gsub!(rule_name, "#{bool_value}")
    end

    def parse_rules
        rule_names = @expression.tr('!&|()', '').split(/\s+/).uniq.sort
        Rules.where(name: rule_names)
    end

    def evaluate_rule(rule, commit, diff)
        RuleAuditor.audit(
            commit,
            rule[:rule_type_id],
            rule[:rule_value],
            diff
        )
    end
end
