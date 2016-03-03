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

private

  def evaluate_patch(commit, patch)
    # Todo change to collect
    results = []
    resolved_expr = "#{@expression}"
    @rules.each do |rule|
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
      resolved_expr.gsub(rule[:name], "#{bool_value}"),
      # Store result even if nil. Expression could be "!someRule"
      { rule_name: rule[:name], result: result }
    ]
  end

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
