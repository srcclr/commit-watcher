require_relative 'rule_auditor'

class ExpressionRule
  def initialize(expression, all_rules)
    @expression = expression
    @all_rules = all_rules
    @auditor = RuleAuditor.new(@all_rules)
    @rule_name_to_rule = Hash[@all_rules.map { |r| [r[:name], r] }]
  end

  def evaluate(commit, diff)
    all_results = []

    if diff
      diff.each do |patch|
        results = evaluate_patch(commit, patch)
        all_results += results if results
      end
    else
      results = evaluate_patch(commit, nil)
      all_results += results if results
    end

    all_results.empty? ? nil : all_results
  end

  def rule_names
    @expression.tr('!&|()', '').split(/\s+/).uniq.sort
  end

  def evaluate_patch(commit, patch)
    results = []
    resolved_expr = @expression.to_s
    rule_names.each do |rule_name|
      rule = @rule_name_to_rule[rule_name]
      resolved_expr, result = resolve_rule(rule, resolved_expr, commit, patch)
      results << result
    end

    #puts "Parsing #{resolved_expr}"
    m = Boolean.parse(resolved_expr)
    m.value ? results : nil
  end

  def resolve_rule(rule, resolved_expr, commit, patch)
    # Send patch as an array so it looks like a diff
    diff = patch ? [patch] : nil
    result = evaluate_rule(rule, commit, diff)
    bool_value = !result.nil?

    [
      resolved_expr.gsub(rule[:name], bool_value.to_s),
      # Store result even if nil. Expression could be "!someRule"
      { rule_name: rule[:name], result: result }
    ]
  end

  def evaluate_rule(rule, commit, diff)
    @auditor.audit(
      commit,
      rule[:rule_type_id],
      rule[:value],
      diff
    )
  end
end
