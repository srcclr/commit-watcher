require 'rails_helper'

describe API::V1::CommitsController, type: :controller, class: Commits do
  before(:each) do
    #FactoryGirl.create(:projects, id: 1, name: 'testy1', rule_sets: '[]')
    #FactoryGirl.create(:projects, id: 2, name: 'testy2', rule_sets: '[]')
    @commit1 = FactoryGirl.create(:commits)
    @commit2 = FactoryGirl.create(:commits)
  end

  describe 'GET index' do
    it 'returns 200 status code' do
      get :index
      expect(response.status).to eq 200
    end

    it 'returns expected commits' do
      get :index
      expect(assigns(:commits)).to eq [@commit1, @commit2]
    end
  end
end
