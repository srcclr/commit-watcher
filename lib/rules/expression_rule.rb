require 'Citrus'

class ExpressionRule
    attr_reader :rule_names

    def initialize(expression)
        @expression = expression
        @rule_names = parse_rule_names
        @rules = nil
    end

    def evaluate(commit, diff)
        @rules ||= Rules.where(name: @rule_names)

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

    def parse_rule_names
        @expression.tr('!&|()', '').split(/\s+/).uniq.sort
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
