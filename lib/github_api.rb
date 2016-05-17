require 'cgi'
require 'net/http'
require 'uri'

class GitHubAPI
  def self.request_json(uri, github_token, params = nil)
    all_json = []
    loop do
      response = request_raw(uri, github_token, params)
      json = JSON.parse(response.read_body, symbolize_names: true)
      p json
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

  def self.request_page(uri, github_token, params = nil, headers = {})
    response = request_raw(uri, github_token, params, headers)
    response.read_body
  end

  def self.request_raw(uri, github_token, params = nil, headers = {})
    Rails.logger.debug "GitHub request: #{uri} #{params}"
    uri = URI(uri)
    uri.query = URI.encode_www_form(params) if params

    response = nil
    loop do
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "token #{github_token}"
        headers.each { |k,v| request[k] = v }
        response = http.request(request)
      end

      being_rate_limited = response.code.to_i == 403 && response['X-RateLimit-Remaining'].to_i == 0
      if being_rate_limited
        reset_time = Time.at(response['X-RateLimit-Reset'].to_i)
        sleep_duration = reset_time - Time.now
        Rails.logger.debug "Rate limited until #{reset_time} (#{sleep_duration} seconds)"
        sleep(sleep_duration)
        next
      end

      break
    end

    return request_raw(uri, github_token, params, headers) if response == Net::HTTPRedirection

    unless response.code.to_i == 200
      raise "Request failed with #{response.code}: #{response.read_body}"
    end

    response
  end
end
