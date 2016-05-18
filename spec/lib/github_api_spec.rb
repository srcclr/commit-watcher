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

require 'rails_helper'

describe 'GitHubAPI' do
  describe '.request_raw' do
    #https://api.github.com/repositories/5625/commits?since=2016-05-01T12%3A45%3A06%2B00%3A00
    let(:url) { 'https://api.github.com/repositories/5625/commits_redirect?since=2016-05-01T12%3A45%3A06%2B00%3A00' }
    let(:github_token) { 'token' }
    subject { GitHubAPI.request_raw(url, github_token) }

    it { should_not be nil }
  end
end
