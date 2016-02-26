require 'git_diff_parser'
require 'activesupport/json_encoder'

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
        #curl -H "Accept: application/vnd.github.diff" https://api.github.com/repos/CalebFenton/simplify/commits/d6dcaa7203e859037bfaa1222f85111feb3dbe93
        commit_url = commit[:url]
        headers = { 'Accept' => 'application/vnd.github.VERSION.diff' }
        diff_raw = GitHubAPI.request_page(commit_url, github_token, nil, headers)
        diff_raw.empty? ? nil : GitDiffParser.parse(diff_raw)
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
        return unless diff

        pattern = Regexp.new(rule)
        filenames = diff.collect { |e| e.file }
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
        return unless diff

        pattern = Regexp.new(rule)
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

    def audit_combination(commit, rule, diff, github_token)
        Rails.logger.warn 'unsupported rule: combination'
    end
end
