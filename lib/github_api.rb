=begin
Copyright 2016 SourceClear Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
=end

require 'cgi'
require 'json'
require 'net/http'
require 'uri'

class GitHubAPI
  COMMITS_URL = 'https://api.github.com/repos/%s/commits'.freeze
  REPOS_URL = 'https://api.github.com/users/%s/repos'.freeze

  def initialize(token, project_username, project_access_token)
    @project_username = project_username
    @project_access_token = project_access_token
    @token = token
  end

  def get_commits(project_name, since_time = nil)
    uri = COMMITS_URL % project_name
    params = since_time ? { since: since_time.iso8601 } : nil
    request_json(uri, params)
  end

  def get_diff(commit_url)
    #curl -H "Accept: application/vnd.github.diff" https://api.github.com/repos/CalebFenton/simplify/commits/d6dcaa7203e859037bfaa1222f85111feb3dbe93
    headers = { 'Accept' => 'application/vnd.github.VERSION.diff' }
    request_page(commit_url, nil, headers)
  end

  def get_repo_names(username)
    uri = REPOS_URL % username
    repos = request_json(uri)
    repos.collect { |r| r[:name] }
  end

  def request_json(uri, params = nil)
    all_json = []
    loop do
      response = request_raw(uri, params)
      json = JSON.parse(response.read_body, symbolize_names: true)
      all_json += json
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

    all_json
  end

  def request_page(uri, params = nil, headers = {})
    response = request_raw(uri, params, headers)
    response.read_body
  end

  def request_raw(uri, params = nil, headers = {})
    Rails.logger.debug "GitHub request: #{uri} #{params}"
    uri = URI(uri)
    uri.query = URI.encode_www_form(params) if params

    response = nil
    loop do
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "token #{@token}"
        request.basic_auth @project_username, @project_access_token unless (@project_username.empty? or @project_access_token.empty?)
        headers.each { |k,v| request[k] = v }
        response = http.request(request)
      end

      being_rate_limited = response.code.to_i == 403 && response['x-ratelimit-remaining'].to_i == 0
      if being_rate_limited
        reset_time = Time.at(response['x-ratelimit-reset'].to_i)
        sleep_duration = reset_time - Time.now
        Rails.logger.debug "Rate limited until #{reset_time} (#{sleep_duration} seconds)"
        begin
          sleep(sleep_duration)
        rescue ArgumentError
          sleep(600)  # 10 Min back off if sleep_duration is negative.
        end
        next
      end

      break
    end

    if response.kind_of?(Net::HTTPRedirection)
      new_url = response['location']
      return request_raw(new_url, params, headers)
    end

    unless response.code.to_i == 200
      raise "Request failed with #{response.code}: #{response.read_body}"
    end

    response
  end
end
