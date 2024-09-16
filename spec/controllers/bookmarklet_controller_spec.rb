require "rails_helper"

RSpec.describe ClipperController do
  render_views

  describe "GET #form" do
    let(:designer) { create(:user) }

    before do
      sign_in(designer)
    end

    context "with archived project" do
      let!(:active_project) { create(:project, :accepted, designers: [designer]) }
      let!(:archived_project) { create(:project, :accepted, :archived, designers: [designer]) }

      before do
        get :form, params: {uuid: designer.bookmarklet_uuid}
      end

      it "active project" do
        expect(response.body).to include(active_project.name)
      end

      it "do not contain archived project" do
        expect(response.body).not_to include(archived_project.name)
      end
    end
  end
end
