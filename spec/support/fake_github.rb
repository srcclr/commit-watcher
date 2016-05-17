require 'sinatra/base'

class FakeGitHub < Sinatra::Base
  get '/repositories/:organization/:project/contributors' do
    json_response 200, 'contributors.json'
  end

  #https://api.github.com/repositories/5625/commits?since=2016-05-01T12%3A45%3A06%2B00%3A00
  get '/repositories/:project_id/commits_redirect' do
    redirect to("/repositories/#{params['project_id']}/commits")
  end

  get '/repositories/:project_id/commits' do
    json_response 200, 'commits.json'
  end

  private

  def json_response(response_code, file_name)
    content_type :json
    status response_code
    File.open("#{File.dirname(__FILE__)}/fixtures/#{file_name}", 'rb').read
  end
end
