require 'rails_helper'

RSpec.describe Api::RoadmapsController, type: :controller do
  let(:response_body) { JSON.parse(response.body) }
  let(:first_body) { response_body[0] }

  before :each do
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  describe 'GET #index' do
    context 'returns http no content' do
      it 'returns no content' do
        get :index

        expect(response).to be_successful
        expect(response).to have_http_status(:ok)
      end
    end

    context 'returns http success' do
      before do
        create :roadmap
      end

      it 'returns http success' do
        get :index

        expect(response.content_type).to eq('application/json')
        expect(response).to be_successful
      end

      it 'return valid JSON all filters' do
        get :index

        expect(first_body['id']).to be_present
        expect(first_body['title']).to be_present
        expect(first_body['description']).to be_present
        expect(first_body['status']).to be_present
      end
    end
  end
end
