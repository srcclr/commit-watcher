require_relative 'expression_rule'

class RuleAuditor
    # The actual content of the line is not exposed. *shrug*
    GitDiffParser::Line.class_eval { attr_reader :content }

    def self.audit(commit, rule_type_id, rule_value, diff)
        case rule_type_id
        when 1
            return unless diff
            audit_filename(Regexp.new(rule_value), diff)
        when 2
            return unless diff
            audit_changed_code_pattern(Regexp.new(rule_value), diff)
        when 3
            return unless diff
            audit_code_pattern(Regexp.new(rule_value), diff)
        when 4
            audit_message_pattern(commit, Regexp.new(rule_value))
        when 5
            audit_author_pattern(commit, Regexp.new(rule_value))
        when 6
            audit_expression(commit, rule_value, diff)
        when 7
            audit_commit_pattern(commit, Regexp.new(rule_value), diff)
        end
    end

private

    def self.audit_filename(pattern, diff)
        filenames = diff.collect { |e| e.file }
        results = filenames.select { |e| e =~ pattern }
        results.empty? ? nil : results
    end

    def self.audit_changed_code_pattern(pattern, diff)
        results = []
        diff.each do |d|
            matches = d.body.scan(pattern)
            next if matches.empty?
            match_offsets = $~.offset(0) # perl, is that you?

            changed_lines = d.changed_lines.collect { |e| e.content }
            changed_ranges = []
            changed_lines.each do |line|
                start = d.body.index(line)
                stop = start + line.length - 1
                changed_ranges << [start, stop]
            end
            next if changed_lines.empty?

            in_changed_range = false
            match_offsets.each_with_index do |offset, idx|
                match = matches[idx]
                changed_ranges.each do |range|
                    next if offset > range[1]

                    end_offset = offset + match.length
                    next if end_offset <= range[0]

                    in_changed_range = true
                    break
                end
                break if in_changed_range
            end
            next unless in_changed_range

            results << {
                file: d.file,
                body: d.body,
                changed_lines: changed_lines,
            }
        end
        results.empty? ? nil : results
    end

    def self.audit_code_pattern(pattern, diff)
        results = []
        diff.each do |d|
            next unless d.body =~ pattern
            results << {
                file: d.file,
                body: d.body,
            }
        end
        results.empty? ? nil : results
    end

    def self.audit_message_pattern(commit, pattern)
        message = commit[:commit][:message]
        (message =~ pattern) ? message : nil
    end

    def self.audit_author_pattern(commit, pattern)
        author_name = commit[:commit][:author][:name]
        author_email = commit[:commit][:author][:email]
        author = "#{author_name} <#{author_email}>"
        (author =~ pattern) ? author : nil
    end

    def self.audit_expression(commit, expression, diff)
        rule = ExpressionRule.new(expression)
        rule.evaluate(commit, diff)
    end

    def self.audit_commit_pattern(commit, pattern, diff)
        results = []
        results << audit_message_pattern(commit, pattern)
        results << audit_code_pattern(commit, pattern, diff) if diff
        results.compact!
        results.empty? ? nil : results
    end
end
