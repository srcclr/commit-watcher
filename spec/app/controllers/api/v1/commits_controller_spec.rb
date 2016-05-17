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

describe API::V1::CommitsController, type: :controller, class: Commits do
  context 'with two random commits' do
    before(:each) do
      @commit1 = FactoryGirl.create(:commit)
      @commit2 = FactoryGirl.create(:commit)
    end

    describe 'GET index with page size = 1' do
      it 'returns multiple pages' do
        get :index, size: 1
        json = JSON.parse(response.body)
        expect(json).to include 'page', 'page_size', 'content', 'next_page'
        expect(json['content']).to eq JSON.parse([@commit1].to_json)
      end
    end

    describe 'GET index with default page size' do
      it 'returns expected content' do
        get :index
        json = JSON.parse(response.body)
        expect(json).to include 'page', 'page_size', 'content'
        expect(json).to_not include 'next_page'
        expect(json['content']).to eq JSON.parse([@commit1, @commit2].to_json)
      end
    end
  end
end
