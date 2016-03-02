require 'Citrus'

class ExpressionRule
    Citrus.load "#{Rails.root}/lib/rules/expression_rule"

    def initialize(expression)
        @expression = expression
        @rules = parse_rules
    end

    def evaluate(commit, diff)
        all_results = []
        diff.each do |patch|
            results = []
            evaluated_expression = "#{@expression}"
            @rules.each do |rule|
                # Send patch as an array so it looks like a diff
                result = evaluate_rule(rule, commit, [patch])
                bool_value = !result.nil?
                evaluated_expression.gsub!(rule[:name], "#{bool_value}")

                # Store result even if nil. Expression could be "!someRule"
                results << { rule_name: rule[:name], result: result }
            end

            #puts "Parsing #{evaluated_expression}"
            m = Boolean.parse(evaluated_expression)
            all_results += results if m.value
        end

        all_results.empty? ? nil : all_results
    end

private

    def parse_rules
        rule_names = @expression.tr('!&|()', '').split(/\s+/).uniq.sort
        Rules.where(name: rule_names)
    end

    def evaluate_rule(rule, commit, diff)
        RuleAuditor.audit(
            commit,
            rule[:rule_type_id],
            rule[:value],
            diff
        )
    end
end
