require "rails_helper"

RSpec.describe Auth::SessionsController do
  subject(:client_login) do
    post user_session_path, params: login_params, headers: request_headers
  end

  let(:login_params) do
    {user: {email:, password:}}
  end
  let(:request_headers) do
    {"HTTP_USER_AGENT" => "some-user-agent"}
  end

  let!(:team) { create(:team) }
  let!(:designer) { create(:user, :designer, team:) }
  let!(:project) { create(:project, designers: [designer, another_designer]) }
  let!(:another_designer) { create(:user, :member, team:) }
  let!(:client) { create(:user, :client, team:, email:, password:) }
  let(:email) { "client@example.org" }
  let(:password) { "password" }

  before do
    project.tap { |p| p.clients << client }.save!
  end

  it "notifies all designers that client logged in" do
    notifications = Notification.where(kind: "client-logged-in", client_id: client.id)
    notified_user_ids = -> { notifications.pluck(:user_id).uniq }
    notifications_group_ids = -> { notifications.pluck(:group_id).uniq.compact }

    expect { client_login }.to change(notifications, :count).by(2)
    expect(notified_user_ids.call).to contain_exactly(designer.id, another_designer.id)
    expect(notifications_group_ids.call.count).to eq 1
  end

  it "sets the signed cookie send_bookmarklet_uuid_to_extension as true" do
    client_login

    signed_cookies =
      ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash).signed

    expect(signed_cookies[:send_bookmarklet_uuid_to_extension]).to eq(true)
  end
end
