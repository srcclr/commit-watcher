require 'net/http'
require 'uri'

class CommitCollector
    include Sidekiq::Worker
    sidekiq_options :queue => :collect_commits

    COMMITS_URL = 'https://api.github.com/repos/%s/commits'

    def perform(project_id, repo_name, last_commit_time, github_token, crawl_frequency, rules)
        Rails.logger.debug "Collecting commits for #{repo_name}"
        latest_commits = get_latest_commits(repo_name, last_commit_time, github_token)
        Rails.logger.debug "Scanning #{latest_commits.size} commits from #{repo_name} with #{rules.count} against rules"

        scan_results = scan(latest_commits, rules, github_token)
        store_scan_results(scan_results)

        # Set next_crawl here only on success rather than in RepoEnquerer in case of error
        set_next_crawl(repo_name, Time.now.to_i + crawl_frequency)
    end

    def get_latest_commits(repo_name, last_commit_time, github_token)
        # TODO: last commits since hash
        uri = COMMITS_URL % repo_name
        response = github_request(uri, github_token)
        response
    end

    def scan(commits, rules, github_token)
        all_results = []
        commits.each do |c|
            scan_results = []
            rules.each do |r|
                scan_result = scan_commit(c, r, github_token)
                next unless scan_result

                scan_results << {
                    rule_id: r[:id],
                    rule_name: r[:name],
                    rule_rule: r[:rule],
                }
            end
            next if scan_results.empty?

            all_results << {
                commit_hash: c['sha1'],
                commit_date: c['commit']['author']['date'],
                scan_results: scan_results,
            }
        end

        all_results
    end

    def scan_commit(commit, rule, github_token)
        case rule[:name]
        when 'commit_author'
            scan_commit_author(commit, rule[:rule])
        when 'pattern'
            scan_commit_pattern(commit, rule[:rule], github_token)
        when 'filename'
            scan_commit_filename(commit, rule[:rule], github_token)
        when 'message_pattern'
            scan_commit_message(commit, rule[:rule])
        when 'code_pattern'
            scan_commit_code(commit, rule[:rule], github_token)
        when 'combination'
            scan_combination(commit, rule[:rule], github_token)
        end
    end

    def scan_commit_pattern(commit, rule, github_token)
        results = []
        result = scan_commit_message(commit, rule)
        results << result if result

        result = scan_commit_code(commit, rule, github_token)
        results << result if result

        results.empty? ? nil : results
    end

    def scan_commit_filename(commit, rule, github_token)
        results = []
        pattern = Regexp.new(rule)
        tree_url = commit['commit']['tree']['url']
        tree_json = github_request(tree_url, github_token)
        tree_json['tree'].each do |e|
            results << e['path'] if e['path'] =~ pattern
        end

        results.empty? ? nil : results
    end

    def scan_commit_author(commit, rule)
        pattern = Regexp.new(rule)
        author_name = commit['commit']['author']['name']
        author_email = commit['commit']['author']['email']
        author = "#{author_name} <#{author_email}>"

        (author =~ pattern) ? author : nil
    end

    def scan_commit_message(commit, rule)
        pattern = Regexp.new(rule)
        message = commit['commit']['message']

        (message =~ pattern) ? message : nil
    end

    def scan_commit_code(commit, rule, github_token)
    end

    def scan_combination(commit, rule, github_token)
        Rails.logger.warn 'unsupported rule: combination'
    end

    def store_scan_results(scan_results)
        Rails.logger.debug "storing scan_results: #{scan_results.size}"
    end

    def set_next_crawl(repo_name, next_crawl)
        Projects[:name => repo_name].set(:next_crawl => next_crawl)
    end

    def github_request(uri, github_token, params = nil)
        Rails.logger.debug "GitHub request: #{uri} #{params}"
        uri = URI(uri)
        uri.query = URI.encode_www_form(params) if params

        response = nil
        Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
            request = Net::HTTP::Get.new(uri)
            request['Authorization'] = "token #{github_token}"
            response = http.request(request) # Net::HTTPResponse object
        end
        JSON.parse(response.read_body)
    end
end

rule_ids = [1,2,3,4]
rules = Rules.graph(:rule_types, :id => :rule_type_id).where(:rules__id => rule_ids).select(:rules__rule, :rule_types__name)
cc = CommitCollector.new
cc.perform(0, 'CalebFenton/simplify', '0', '567860bb4fb5890e3523bb8f95c8120788d51761', 1440, rules)
