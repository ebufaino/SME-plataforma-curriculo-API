require 'rails_helper'

RSpec.describe Api::ActivitiesController, type: :controller do
  let(:response_body) { JSON.parse(response.body) }

  before :each do
    request.env['HTTP_ACCEPT'] = 'application/json'
  end

  describe 'GET #show' do
    let(:activity_sequence) { create :activity_sequence }
    let(:activity) do
      create :activity,
             activity_sequence_id: activity_sequence.id
    end

    context 'returns http no content' do
      it 'returns no content' do
        get :show, params: {
          activity_sequence_slug: activity_sequence.slug,
          activity_slug: 'invalid-slug'
        }

        expect(response).to be_successful
        expect(response).to have_http_status(:no_content)
      end
    end

    context 'returns http success' do
      it 'returns http success' do
        get :show, params: {
          activity_sequence_slug: activity_sequence.slug,
          activity_slug: activity.slug
        }

        expect(response.content_type).to eq('application/json')
        expect(response).to be_successful
      end

      it 'return valid JSON all filters' do
        activity_sequence = create :activity_sequence
        list = create_list :activity, 3, activity_sequence: activity_sequence
        middle_activity = Activity.all.last(3)[1]
        get :show, params: {
          activity_sequence_slug: activity_sequence.slug,
          activity_slug: middle_activity.slug
        }

        expect(response_body['sequence']).to be_present
        expect(response_body['title']).to be_present
        expect(response_body['estimated_time']).to be_present
        expect(response_body['activity_sequence']).to be_present
        expect(response_body['image_attributes']).to be_present
        expect(response_body['activity_types']).to_not be_present
        expect(response_body['next_object']).to be_present
        expect(response_body['last_object']).to be_present
        expect(response_body['content']).to be_present
      end

      it 'return valid activity sequence JSON' do
        get :show, params: {
          activity_sequence_slug: activity_sequence.slug,
          activity_slug: activity.slug
        }

        expect(response_body['activity_sequence']).to be_present
        expect(response_body['activity_sequence']['title']).to be_present
        expect(response_body['activity_sequence']['slug']).to be_present
        expect(response_body['activity_sequence']['year']).to be_present
        expect(response_body['activity_sequence']['main_curricular_component']).to be_present
        expect(response_body['activity_sequence']['image_attributes']).to be_present
      end

      it 'return valid main_curricular_component on activity sequence JSON' do
        get :show, params: {
          activity_sequence_slug: activity_sequence.slug,
          activity_slug: activity.slug
        }

        expect(response_body['activity_sequence']['main_curricular_component']).to be_present
        expect(response_body['activity_sequence']['main_curricular_component']['name']).to be_present
        expect(response_body['activity_sequence']['main_curricular_component']['color']).to be_present
      end

      it 'return valid activity types JSON' do
        get :show, params: {
          activity_sequence_slug: activity_sequence.slug,
          activity_slug: activity.slug
        }

        expect(response_body['activity_types']).to_not be_present
      end

      it 'return valid curricular components JSON' do
        get :show, params: {
          activity_sequence_slug: activity_sequence.slug,
          activity_slug: activity.slug
        }

        expect(response_body['curricular_components']).to be_present
        expect(response_body['curricular_components'][0]['name']).to be_present
      end

      it 'return valid learning objectives JSON' do
        get :show, params: {
          activity_sequence_slug: activity_sequence.slug,
          activity_slug: activity.slug
        }

        expect(response_body['learning_objectives']).to be_present
        expect(response_body['learning_objectives'][0]['code']).to be_present
        expect(response_body['learning_objectives'][0]['description']).to be_present
        expect(response_body['learning_objectives'][0]['color']).to be_present
      end
    end
  end
end
