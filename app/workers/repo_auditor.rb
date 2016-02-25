require 'net/http'
require 'uri'
require 'cgi'

class RepoAuditor
    include Sidekiq::Worker
    sidekiq_options :queue => :audit_repo

    COMMITS_URL = 'https://api.github.com/repos/%s/commits'
    DIFF_RULES_TYPE_IDS = [2,5,6]

    def perform(project_id, repo_name, last_commit_time, github_token, audit_frequency, rules)
        # Set next audit now even though there may be an error because sometimes the audit
        # takes longer than the enquerer frequency and we want to avoid double queueing.
        next_audit = Time.now.to_i + audit_frequency
        Projects[:id => project_id].update(:next_audit => next_audit)

        last_commit_time = Time.parse(last_commit_time)
        rules = JSON.parse(rules)

        Rails.logger.debug "Collecting commits for #{repo_name}"
        latest_commits = get_latest_commits(
            repo_name, last_commit_time, github_token
        )
        Rails.logger.debug "Auditing #{latest_commits.size} commits from #{repo_name} with #{rules.count} rules"
        return if latest_commits.size == 0

        audit_results = audit(latest_commits, rules, github_token)
        audit_results.each { |e| e[:project_id] = project_id }
        store_audit_results(audit_results)

        last_commit_time = latest_commits.collect { |e| Time.parse(e['commit']['author']['date']) }.max
        Projects[:id => project_id].update(:last_commit_time => last_commit_time)
    end

    def get_latest_commits(repo_name, last_commit_time, github_token)
        uri = COMMITS_URL % repo_name
        since_time = last_commit_time + 1
        params = { since: since_time.iso8601 }
        response = github_request_json(uri, github_token, params)
        response
    end

    def get_commit_diff(commit, github_token)
        commit_url = commit['url']
        body = github_request_page(commit_url, github_token, nil,
            {'Accept' => 'application/vnd.github.VERSION.diff'})
        body
    end

    def audit(commits, rules, github_token)
        all_results = []
        commits.each do |c|
            diff = nil
            unless (rules.collect { |r| r[:id] } & DIFF_RULES_TYPE_IDS).empty?
                diff = get_commit_diff(c, github_token)
            end
            audit_results = []
            rules.each do |r|
                audit_result = audit_commit(c, r, diff, github_token)
                next unless audit_result

                audit_results << {
                    rule_id: r[:id],
                    rule_type: r[:name],
                    rule_rule: r[:rule],
                    audit_result: audit_result,
                }
            end
            next if audit_results.empty?

            all_results << {
                commit_hash: c['sha'],
                commit_date: c['commit']['author']['date'],
                audit_results: audit_results,
            }
        end

        all_results
    end

    def audit_commit(commit, rule, diff, github_token)
        case rule[:name]
        when 'commit_author'
            audit_commit_author(commit, rule[:rule])
        when 'pattern'
            audit_commit_pattern(commit, rule[:rule], diff, github_token)
        when 'filename'
            audit_commit_filename(commit, rule[:rule], diff, github_token)
        when 'message_pattern'
            audit_commit_message(commit, rule[:rule])
        when 'code_pattern'
            audit_commit_code(commit, rule[:rule], diff, github_token)
        when 'combination'
            audit_combination(commit, rule[:rule], diff, github_token)
        end
    end

    def audit_commit_pattern(commit, rule, diff, github_token)
        results = []
        result = audit_commit_message(commit, rule)
        results << result if result

        result = audit_commit_code(commit, rule, diff, github_token)
        results << result if result

        results.empty? ? nil : results
    end

    def audit_commit_filename(commit, rule, diff, github_token)
        #diff --git a/some/path/Heap.java b/some/path/Heap.java
        diff_cmd_parts = diff.lines.first.split(' ')
        filenames = diff_cmd_parts[2..3].collect { |e| e[2..-1] }

        pattern = Regexp.new(rule)
        results = filenames.select { |e| e =~ pattern }
        results.empty? ? nil : results
    end

    def audit_commit_author(commit, rule)
        pattern = Regexp.new(rule)
        author_name = commit['commit']['author']['name']
        author_email = commit['commit']['author']['email']
        author = "#{author_name} <#{author_email}>"

        (author =~ pattern) ? author : nil
    end

    def audit_commit_message(commit, rule)
        pattern = Regexp.new(rule)
        message = commit['commit']['message']

        (message =~ pattern) ? message : nil
    end

    def audit_commit_code(commit, rule, diff, github_token)
    end

    def audit_combination(commit, rule, diff, github_token)
        Rails.logger.warn 'unsupported rule: combination'
    end

    def store_audit_results(audit_results)
        Rails.logger.debug "Storing audit results: #{audit_results.size}"
        audit_results.each do |e|
            Commits.insert(:project_id => e[:project_id], :commit_date => Time.iso8601(e[:commit_date]),
                :commit_hash => e[:commit_hash], :audit_results => e[:audit_results].to_s)
        end
    end

    def github_request_json(uri, github_token, params = nil)
        json = []
        loop do
            response = github_request_raw(uri, github_token, params)
            json += JSON.parse(response.read_body)
            break unless response['Link']

            # Link: <https://api.github.com/repositories/15958676/commits?page=3>; rel="next", <https://api.github.com/repositories/15958676/commits?page=1>; rel="first", <https://api.github.com/repositories/15958676/commits?page=1>; rel="prev"
            pattern = /<([^>]+)>; rel=\"([^\"]+)\"/
            links = {}
            response['Link'].split(', ').each do |e|
                m = e.match(pattern)
                links.merge!({ m[2] => m[1] })
            end
            next_url = links['next']
            break unless next_url

            Rails.logger.debug "Continuing page request: #{next_url}"
            uri = next_url.split('?')[0]
            params = CGI::parse(URI.parse(next_url).query)
        end

        json
    end

    def github_request_page(uri, github_token, params = nil, headers = {})
        response = github_request_raw(uri, github_token, params, headers)
        response.read_body
    end

    def github_request_raw(uri, github_token, params = nil, headers = {})
        Rails.logger.debug "GitHub request: #{uri} #{params}"
        uri = URI(uri)
        uri.query = URI.encode_www_form(params) if params

        response = nil
        loop do
            Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
                request = Net::HTTP::Get.new(uri)
                request['Authorization'] = "token #{github_token}"
                headers.each { |k,v| request[k] = v }
                response = http.request(request)
            end

            being_rate_limited = response.code.to_i == 403 && response['X-RateLimit-Remaining'].to_i == 0
            if being_rate_limited
                reset_time = Time.at(response['X-RateLimit-Reset'].to_i)
                sleep_duration = reset_time - Time.now
                Rails.logger.debug "Rate limited by GitHub until #{reset_time} (#{sleep_duration} seconds)"
                sleep(sleep_duration)
                next
            end

            break
        end

        unless response.code.to_i == 200
            Rails.logger.error "Request failed with #{response.code}: #{response.read_body}"
        end

        response
    end
end
