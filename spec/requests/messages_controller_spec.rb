RSpec.describe "Messages", type: :request do
  let(:team) { create(:team) }
  let!(:designer) { create(:user, :designer, team:) }
  let!(:project) { create(:project, designers: [designer]) }

  before do
    sign_in(designer)
  end

  describe "POST /projects/:project_id/messages" do
    before do
      allow(designer).to receive(:track_event_in_mixpanel).and_return(true)
    end

    context "with valid parameters in a client discussion" do
      let(:valid_params) { {message: {text: "Hello, world!"}, discussion_kind: "client", origin_controller: "invoices", origin_action: "index"} }

      it "creates a new Message" do
        expect {
          post project_messages_path(project_id: project.id), params: valid_params
        }.to change(Message, :count).by(1)
      end

      it "associates the message with the current discussion thread" do
        post project_messages_path(project_id: project.id), params: valid_params
        message = Message.last
        expect(message.discussion).to eq(project.client_discussion)
      end

      it "associates the message with the current user" do
        post project_messages_path(project_id: project.id), params: valid_params
        message = Message.last
        expect(message.sender).to eq(designer)
      end

      it "returns a success response" do
        post project_messages_path(project_id: project.id), params: valid_params
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to eq({"success" => "success"})
      end

      it "sends the event to mixpanel" do
        expected_payload = {
          "Message Type": "Client",
          "Messaged On": "Invoices",
          "User Role": "Designer",
          "Design Referenced": "No",
          Attachments: 0,
          project_id: project.id,
          "Project Name": project.name
        }
        post project_messages_path(project_id: project.id), params: valid_params
        expect(designer).to have_received(:track_event_in_mixpanel).with("Message Posted", expected_payload)
      end

      context "when also sending a file" do
        let(:file) { fixture_file_upload(Rails.root.join("spec/support/files/chair.jpg").to_s) }
        let(:valid_params) { {message: {text: "Hello, world!", images: [file]}, discussion_kind: "client", origin_controller: "invoices", origin_action: "index"} }

        it "creates an item attached to the message" do
          expect {
            post project_messages_path(project_id: project.id), params: valid_params
          }.to change(Item, :count).by(1)
        end

        it "creates an image attached to the message through the item" do
          post project_messages_path(project_id: project.id), params: valid_params
          message = Message.last
          expect(message.items.size).to eq(1)
          expect(message.items.last.image?).to be(true)
        end

        it "sends the event to mixpanel with number of attachments" do
          expected_payload = {
            "Message Type": "Client",
            "Messaged On": "Invoices",
            "User Role": "Designer",
            "Design Referenced": "No",
            Attachments: 1,
            project_id: project.id,
            "Project Name": project.name
          }
          post project_messages_path(project_id: project.id), params: valid_params
          expect(designer).to have_received(:track_event_in_mixpanel).with("Message Posted", expected_payload)
        end
      end

      context "when a board is linked to the message" do
        let(:board) { create(:board, project:) }
        let(:valid_params) { {message: {text: "Hello, world!", board_id: board.id}, discussion_kind: "client", origin_controller: "invoices", origin_action: "index"} }

        it "returns a success response" do
          post project_messages_path(project_id: project.id), params: valid_params
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)).to eq({"success" => "success"})
        end

        it "links message and board" do
          post project_messages_path(project_id: project.id), params: valid_params
          message = Message.last
          expect(message.board).to eq(board)
        end

        it "sends the event to mixpanel with design referenced flag" do
          expected_payload = {
            "Message Type": "Client",
            "Messaged On": "Invoices",
            "User Role": "Designer",
            "Design Referenced": "Yes",
            Attachments: 0,
            project_id: project.id,
            "Project Name": project.name
          }
          post project_messages_path(project_id: project.id), params: valid_params
          expect(designer).to have_received(:track_event_in_mixpanel).with("Message Posted", expected_payload)
        end
      end

      context "when only the sender is in the project" do
        it "changes the number of UserDiscussion in db" do
          expect {
            post project_messages_path(project_id: project.id), params: valid_params
          }.to change(UserDiscussion, :count).by(1)
        end

        it "does not increment number of unreads" do
          expect {
            post project_messages_path(project_id: project.id), params: valid_params
          }.to change(UserDiscussion, :count).by(1)
        end

        it "does not set the number of unread for sender" do
          post project_messages_path(project_id: project.id), params: valid_params
          expect(project.client_discussion.user_discussions.where(user: designer).first.unread_message_count).to eq(0)
        end
      end

      context "when another user is in the project alongside the designer" do
        let(:other_designer) { create(:user, :manager, team:) }

        before { project.project_designers << ProjectDesigner.create(project:, designer: other_designer) }

        it "changes the number of UserDiscussion in db" do
          expect {
            post project_messages_path(project_id: project.id), params: valid_params
          }.to change(UserDiscussion, :count).by(2)
        end

        it "sets the number of unread for recepients" do
          post project_messages_path(project_id: project.id), params: valid_params
          expect(project.client_discussion.user_discussions.where(user: other_designer).first.unread_message_count).to eq(1)
        end
      end
    end

    context "with valid parameters in a team/private discussion" do
      let(:valid_params) { {message: {text: "Hello, world!"}, discussion_kind: "team", origin_controller: "invoices", origin_action: "index"} }

      it "creates a new Message" do
        expect {
          post project_messages_path(project_id: project.id), params: valid_params
        }.to change(Message, :count).by(1)
      end

      it "associates the message with the current discussion thread" do
        post project_messages_path(project_id: project.id), params: valid_params
        message = Message.last
        expect(message.discussion).to eq(project.team_discussion)
      end

      it "associates the message with the current user" do
        post project_messages_path(project_id: project.id), params: valid_params
        message = Message.last
        expect(message.sender).to eq(designer)
      end

      it "returns a success response" do
        post project_messages_path(project_id: project.id), params: valid_params
        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to eq({"success" => "success"})
      end

      it "sends the event to mixpanel with team message type" do
        expected_payload = {
          "Message Type": "Team",
          "Messaged On": "Invoices",
          "User Role": "Designer",
          "Design Referenced": "No",
          Attachments: 0,
          project_id: project.id,
          "Project Name": project.name
        }
        post project_messages_path(project_id: project.id), params: valid_params
        expect(designer).to have_received(:track_event_in_mixpanel).with("Message Posted", expected_payload)
      end

      context "when also sending a file" do
        let(:file) { fixture_file_upload(Rails.root.join("spec/support/files/chair.jpg").to_s) }
        let(:valid_params) { {message: {text: "Hello, world!", images: [file]}, discussion_kind: "team", origin_controller: "invoices", origin_action: "index"} }

        it "creates an item attached to the message" do
          expect {
            post project_messages_path(project_id: project.id), params: valid_params
          }.to change(Item, :count).by(1)
        end

        it "creates an image attached to the message through the item" do
          post project_messages_path(project_id: project.id), params: valid_params
          message = Message.last
          expect(message.items.size).to eq(1)
          expect(message.items.last.image?).to be(true)
        end
      end

      context "when a board is linked to the message" do
        let(:board) { create(:board, project:) }
        let(:valid_params) { {message: {text: "Hello, world!", board_id: board.id}, discussion_kind: "team", origin_controller: "invoices", origin_action: "index"} }

        it "returns a success response" do
          post project_messages_path(project_id: project.id), params: valid_params
          expect(response).to have_http_status(:created)
          expect(JSON.parse(response.body)).to eq({"success" => "success"})
        end

        it "links message and board" do
          post project_messages_path(project_id: project.id), params: valid_params
          message = Message.last
          expect(message.board).to eq(board)
        end
      end

      context "when only the sender is in the project" do
        it "changes the number of UserDiscussion in db" do
          expect {
            post project_messages_path(project_id: project.id), params: valid_params
          }.to change(UserDiscussion, :count).by(1)
        end

        it "does not increment number of unreads" do
          expect {
            post project_messages_path(project_id: project.id), params: valid_params
          }.to change(UserDiscussion, :count).by(1)
        end

        it "does not set the number of unread for sender" do
          post project_messages_path(project_id: project.id), params: valid_params
          expect(project.team_discussion.user_discussions.where(user: designer).first.unread_message_count).to eq(0)
        end
      end

      context "when another user is in the project alongside the designer" do
        let(:other_designer) { create(:user, :manager, team:) }

        before { project.project_designers << ProjectDesigner.create(project:, designer: other_designer) }

        it "changes the number of UserDiscussion in db" do
          expect {
            post project_messages_path(project_id: project.id), params: valid_params
          }.to change(UserDiscussion, :count).by(2)
        end

        it "sets the number of unread for recepients" do
          post project_messages_path(project_id: project.id), params: valid_params
          expect(project.team_discussion.user_discussions.where(user: other_designer).first.unread_message_count).to eq(1)
        end
      end
    end

    context "with invalid parameters" do
      context "such as badly formatted params" do
        it "does not create a new Message" do
          expect {
            post project_messages_path(project_id: project.id), params: {text: "", origin_controller: "invoices", origin_action: "index"}
          }.to change(Message, :count).by(0)
        end

        it "returns an unprocessable entity status" do
          post project_messages_path(project_id: project.id), params: {text: "", origin_controller: "invoices", origin_action: "index"}
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "such as an empty message" do
        it "does not create a new Message" do
          expect {
            post project_messages_path(project_id: project.id), params: {message: {text: ""}, origin_controller: "invoices", origin_action: "index"}
          }.to change(Message, :count).by(0)
        end

        it "returns an unprocessable entity status" do
          post project_messages_path(project_id: project.id), params: {message: {text: ""}, origin_controller: "invoices", origin_action: "index"}
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
