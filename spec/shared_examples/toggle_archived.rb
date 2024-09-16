RSpec.shared_examples "a toggle archived action" do |resource, path_helper, trait = nil|
  let(:resource_instance) { create(resource, trait) }
  let(:archived_resource_instance) { create(resource, trait, archived: true) }

  let(:headers) do
    {
      AUTHORIZATION: ActionController::HttpAuthentication::Basic.encode_credentials("admin", "admin")
    }
  end

  describe "POST #toggle_archived" do
    context "when the #{resource} is not archived" do
      before do
        request.headers.merge!(headers)
        post :toggle_archived, params: {id: resource_instance.id}
        resource_instance.reload
      end

      it "archives the #{resource}" do
        expect(resource_instance.archived).to be(true)
      end

      it "sets the flash notice" do
        expect(flash[:notice]).to eq("#{resource_instance.class.name} #{resource_instance.name} archived successfully.")
      end

      it "redirects to the index page" do
        expect(response).to redirect_to(send(path_helper))
      end
    end

    context "when the #{resource} is archived" do
      before do
        request.headers.merge!(headers)
        post :toggle_archived, params: {id: archived_resource_instance.id}
        archived_resource_instance.reload
      end

      it "unarchives the #{resource}" do
        expect(archived_resource_instance.archived).to be(false)
      end

      it "sets the flash notice" do
        expect(flash[:notice]).to eq("#{resource_instance.class.name} #{archived_resource_instance.name} restored successfully.")
      end

      it "redirects to the index page" do
        expect(response).to redirect_to(send(path_helper))
      end
    end
  end
end
