require 'rails_helper'

RSpec.describe User, type: :model do
  it_behaves_like 'jti_matcher_and_sme_strategy_spec'

  let(:subject) { build :user }

  describe 'Associations' do
    it { should have_one(:teacher) }
  end

  describe 'Validations' do
    describe 'is valid' do
      it 'with valid attributes' do
        expect(subject).to be_valid
      end

      it 'create users different username and equals email' do
        # case_sensitive: false
        subject = create :user, email: '', username: 'test'
        new_subject = build :user, email: '', username: 'test2'

        expect(new_subject).to be_valid
      end
    end

    describe 'is not valid' do
      it 'if username and email is nil' do
        subject = build :user, username: nil, email: nil

        expect(subject).to_not be_valid
      end

      context 'if a username is nil' do
        let(:subject) { build :user, username: nil }

        it 'without a email' do
          subject.email = nil

          expect(subject).to_not be_valid
        end

        it 'if the email already exists' do
          # case_sensitive: false
          subject = create :user, username: nil, email: 'test@test.com'
          new_subject = build :user, username: nil, email: 'TEST@test.com'

          expect(new_subject).to_not be_valid
        end
      end

      context 'if a email is nil' do
        let(:subject) { build :user, email: '' }

        it 'without a username' do
          subject.username = nil

          expect(subject).to_not be_valid
        end

        it 'if the username already exists' do
          # case_sensitive: false
          subject = create :user, email: '', username: 'test'
          new_subject = build :user, email: '', username: 'TEST'

          expect(new_subject).to_not be_valid
        end
      end

      context 'if email and username present' do
        it 'not valid if email already exists' do
          subject = create :user
          new_subject = build :user, email: subject.email

          expect(new_subject).to_not be_valid
        end

        it 'not valid if username already exists' do
          subject = create :user
          new_subject = build :user, username: subject.username

          expect(new_subject).to_not be_valid
        end
      end
    end
  end

  describe 'Getters' do
    context 'login' do
      it 'return username first' do
        expect(subject.login).to eq(subject.username)
      end

      it 'return email if username is nil' do
        subject = create :user, username: nil
        expect(subject.login).to eq(subject.email)
      end

      it 'return username if email is empty' do
        subject = create :user, email: ''
        expect(subject.login).to eq(subject.username)
      end
    end

    context 'refresh_token_params' do
      it 'return valid hash' do
        expected = { username: subject.username, refreshToken: subject.sme_refresh_token }

        expect(subject.refresh_token_params).to eq(expected)
      end
    end
  end

  describe 'Callbacks' do
    context 'on after_create' do
      context 'assign_teacher' do
        it 'not assign teacher if username is blank' do
          subject = create :user, username: nil

          expect(subject.teacher).to be nil
        end

        it 'not assign teacher if teacher already exists' do
          user = create :user, username: nil
          teacher = create :teacher, user: user

          expect(user.teacher).to eq(teacher)
        end

        it 'assign teacher if not skip crerating teacher' do
          subject_false = create :user, _skip_creating_teacher: false
          subject_nil   = create :user, _skip_creating_teacher: nil

          expect(subject_false.teacher).to_not be nil
          expect(subject_nil.teacher).to_not   be nil
        end
      end
    end
  end

  let(:claims) do
    {
      "username": user.username,
      "jti": user.jti,
      "exp": (Time.now + 150).to_i,
      "iss": ENV['SME_JWT_ISSUER'],
      "aud": ENV['SME_JWT_AUDIENCE']
    }
  end

  let(:invalid_claims) do
    {
      "exp": (Time.now - 150).to_i
    }
  end

  let(:user) { create :user, :with_teacher }
  let(:refresh_token) { 'TokjrJZ1JnrhJX8A+meznJg+Gi//1tmK6Ysuc6MA4WQ=' }
  let(:valid_sme_token) { JWT.encode(claims, nil, 'none') }
  let(:invalid_sme_token) { JWT.encode(invalid_claims, nil, 'none') }
  let(:credentials) { { username: user.username, password: user.password } }
  let(:invalid_credentials) { { username: user.username, password: 'WRONG' } }
  let(:request_headers) do
    {
      'Accept' => 'application/hal+json, application/json;q=0.5',
      'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
      'Connection' => 'Keep-Alive',
      'Content-Type' => 'application/json; charset=utf-8',
      'User-Agent' => 'Flexirest/1.7.5'
    }
  end

  let(:response_body) do
    {
      "name": user.username,
      "username": user.username,
      "email": user.email,
      "sgpToken": {
        "token": valid_sme_token,
        "refreshToken": refresh_token
      }
    }
  end

  let(:response_body_invalid_token) do
    {
      "token": invalid_sme_token,
      "refreshToken": refresh_token
    }
  end

  describe 'Authenticate in SME' do
    it 'return nil unless credentials' do
      expected = User.authenticate_in_sme nil

      expect(expected).to be false
    end

    it 'return TRUE if VALID credentials' do
      stub_request(:post, "#{ENV['SME_AUTHENTICATION_BASE_URL']}/LoginIdentity")
        .with(
          body: {
            'username' => user.username,
            'password' => user.password
          },
          headers: request_headers
        ).to_return(status: 200, body: response_body.to_json, headers: request_headers)

      expected = User.authenticate_in_sme credentials

      expect(expected).to be true
    end

    it 'return FALSE if INVALID credentials' do
      stub_request(:post, "#{ENV['SME_AUTHENTICATION_BASE_URL']}/LoginIdentity")
        .with(
          body: {
            'username' => user.username,
            'password' => 'WRONG'
          },
          headers: request_headers
        ).to_return(status: 401, body: {}.to_json, headers: request_headers)

      expected = User.authenticate_in_sme invalid_credentials

      expect(expected).to be false
    end

    it 'return nil if sme reponse a invalid token' do
      invalid_response =     {
        "token": invalid_sme_token,
        "refreshToken": refresh_token
      }.to_json
      stub_request(:post, "#{ENV['SME_AUTHENTICATION_BASE_URL']}/LoginIdentity")
        .with(
          body: {
            'username' => user.username,
            'password' => user.password
          },
          headers: request_headers
        ).to_return(status: 200, body: invalid_response, headers: request_headers)

      expected = User.authenticate_in_sme credentials

      expect(expected).to be false
    end
  end

  describe 'find_or_create_by_auth_params' do
    context 'if user already exists' do
      let(:token_validator) { TokenValidator.new(valid_sme_token, refresh_token) }

      it 'update sme tokens' do
        os = OpenStruct.new(response_body)
        response = User.find_or_create_by_auth_params(os, credentials)
        user.reload

        expect(response).to be true
      end
    end

    context 'if user NOT exists' do
      let(:new_username) { 'new_username' }
      let(:new_email) { 'new_email@gedu.com' }
      let(:claims) do
        {
          "username": new_username,
          "jti": user.jti,
          "exp": (Time.now + 150).to_i,
          "iss": ENV['SME_JWT_ISSUER'],
          "aud": ENV['SME_JWT_AUDIENCE']
        }
      end
      let(:valid_sme_token) { JWT.encode(claims, nil, 'none') }
      let(:token_validator) { TokenValidator.new(valid_sme_token, refresh_token) }


      let(:new_response_body) do
        {
          "name": new_username,
          "username": new_username,
          "email": new_email,
          "sgpToken": {
            "token": valid_sme_token,
            "refreshToken": refresh_token
          }
        }
      end

      it 'create user on database with tokens' do
        os = OpenStruct.new(new_response_body)
        response = User.find_or_create_by_auth_params(os, credentials)

        user = User.find_by(username: new_username)

        expect(response).to be true
        expect(user).to_not be nil
        expect(user.username).to eq(new_username)
      end
    end
  end
end
