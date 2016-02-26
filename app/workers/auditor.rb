require_relative '../../lib/github_api'

class Auditor
    include Sidekiq::Worker
    sidekiq_options :queue => :audit_commits

    DIFF_RULES_TYPE_IDS = [2, 5, 6]

    def perform(project_id, commit, rules, github_token)
        commit = JSON.parse(commit, symbolize_names: true)
        rules = JSON.parse(rules, symbolize_names: true)

        diff = nil
        unless (rules.collect { |r| r[:id] } & DIFF_RULES_TYPE_IDS).empty?
            diff = get_commit_diff(commit, github_token)
        end

        audit_results = []
        rules.each do |r|
            audit_result = audit_commit(commit, r, diff, github_token)
            next unless audit_result

            audit_results << {
                rule_id: r[:id],
                rule_type: r[:name],
                rule: r[:rule],
                audit_result: audit_result,
            }
        end
        return if audit_results.empty?

        record = {
            project_id: project_id,
            commit_hash: commit[:sha],
            commit_date: Time.iso8601(commit[:commit][:author][:date]),
            audit_results: audit_results.to_json,
        }

        Commits.insert(record)
    end

    def get_commit_diff(commit, github_token)
        commit_url = commit[:url]
        headers = { 'Accept' => 'application/vnd.github.VERSION.diff' }
        GitHubAPI.request_page(commit_url, github_token, nil, headers)
    end

    def audit_commit(commit, rule, diff, github_token)
        case rule[:name]
        when 'commit_author'
            audit_commit_author(commit, rule[:rule])
        when 'pattern'
            audit_commit_pattern(commit, rule[:rule], diff)
        when 'filename'
            audit_commit_filename(commit, rule[:rule], diff)
        when 'message_pattern'
            audit_commit_message(commit, rule[:rule])
        when 'code_pattern'
            audit_commit_code(commit, rule[:rule], diff)
        when 'combination'
            audit_combination(commit, rule[:rule], diff, github_token)
        end
    end

    def audit_commit_pattern(commit, rule, diff)
        results = []
        result = audit_commit_message(commit, rule)
        results << result if result

        result = audit_commit_code(commit, rule, diff)
        results << result if result

        results.empty? ? nil : results
    end

    def audit_commit_filename(commit, rule, diff)
        #diff --git a/some/path/Heap.java b/some/path/Heap.java
        return if diff.empty?

        diff_cmd_parts = diff.lines.first.split(' ')
        filenames = diff_cmd_parts[2..3].collect { |e| e[2..-1] }

        pattern = Regexp.new(rule)
        results = filenames.select { |e| e =~ pattern }
        results.empty? ? nil : results
    end

    def audit_commit_author(commit, rule)
        pattern = Regexp.new(rule)
        author_name = commit[:commit][:author][:name]
        author_email = commit[:commit][:author][:email]
        author = "#{author_name} <#{author_email}>"

        (author =~ pattern) ? author : nil
    end

    def audit_commit_message(commit, rule)
        pattern = Regexp.new(rule)
        message = commit[:commit][:message]

        (message =~ pattern) ? message : nil
    end

    def audit_commit_code(commit, rule, diff)
        #curl -H "Accept: application/vnd.github.diff" https://api.github.com/repos/CalebFenton/simplify/commits/d6dcaa7203e859037bfaa1222f85111feb3dbe93
        pattern = Regexp.new(rule)

        (diff =~ pattern) ? diff : nil
    end

    def audit_combination(commit, rule, diff, github_token)
        Rails.logger.warn 'unsupported rule: combination'
    end
end
