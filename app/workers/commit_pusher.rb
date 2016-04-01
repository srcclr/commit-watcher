require 'net/https'
require 'uri'

class CommitPusher
  include Sidekiq::Worker
  sidekiq_options queue: :push_commits

  def perform
    uri = URI.parse(PushCommits[:endpoint])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Post.new(uri.path)

    Rails.logger.debug "Pushing commits to #{uri.host}:#{uri.port}"

    page_no = 1
    page_size = 100

    while page_no
      Rails.logger.debug "Pushing commit page #{page_no}"

      content = Commits.dataset.paginate(page_no, page_size)
      page_no = content.next_page

      request['commits'] = content.to_json
      response = http.request(request)

      if response.status.to_i != 200
        # Sidekiq will retry this later
        fail "Unexpected commit push endpoint response: #{response.status}\n#{response.body}"
      end
    end

    # If no errors, assume the endpoint got everything
    Commits.truncate
  end
end
