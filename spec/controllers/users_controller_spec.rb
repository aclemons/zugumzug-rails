require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  let(:user_data) { { email: 'timmi@tester.com', password: 'power365', name: 'timmi' } }
  let(:service_clazz) { class_double(User).as_stubbed_const }
  let(:service) { instance_double(service_clazz) }

  describe "POST #create" do
    context "successfully saved" do
      before do
        expect(service_clazz).to receive(:new).with(user_data).and_return(service)
        expect(service).to receive(:save).and_return(true)
      end

      it "returns http 201" do
        post :create, user: user_data, :format => :json
        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq("application/json")
        expect(response.location).to be_truthy
      end
    end

    context "with invalid data" do
      it "returns http 201" do
        post :create, user: user_data.reject {|k,v| k == :name }, :format => :json
        expect(response).to have_http_status(:bad_request)
        expect(response.content_type).to eq("application/json")
      end
    end
  end

  describe "GET #show" do
    let(:user_id) { "1" }

    context "user exists" do
      before do
        expect(service_clazz).to receive(:find).with(user_id).and_return(service)
        expect(service_clazz).to receive(:find_by).with(email: user_data[:email]).and_return(service)
        expect(service).to receive(:authenticated?).with(user_data[:password]).and_return(true)
        expect(service).to receive(:id).and_return(user_id.to_i)
      end

      it "returns http 200 and the user" do
        @request.env["HTTP_AUTHORIZATION"] = "Basic " + Base64::encode64("#{user_data[:email]}:#{user_data[:password]}")
        get :show, id: user_id, :format => :json
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq("application/json")
      end
    end
  end
end
