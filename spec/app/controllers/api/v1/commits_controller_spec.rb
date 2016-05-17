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
