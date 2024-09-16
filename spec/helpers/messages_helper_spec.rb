require "rails_helper"

RSpec.describe MessagesHelper, type: :helper do
  let(:designer) { create(:user, role: "designer") }
  let(:project) { create(:project, designers: [designer], created_by: designer) }

  before do
    helper.extend(ControllerHelperMethods)
    helper.current_user = designer
  end

  describe "#render_discussion_panel_block" do
    context "when the project is present" do
      it "returns the correct partial" do
        result = helper.render_discussion_panel_block(project)
        expect(result).to include("discussion-panel")
      end
    end

    context "when the project is blank" do
      it "returns nil" do
        expect(helper.render_discussion_panel_block(nil)).to be_nil
      end
    end
  end

  describe "#discussion_panel_empty_text" do
    context "when the user is a designer and discussion is team/private" do
      it "returns the correct empty message for a designer" do
        html_output = helper.discussion_panel_empty_text("designer", "team")
        expect(html_output).to include("Message your team privately…")
        expect(html_output).to include("Keep an ongoing chat about project updates with your team!")
      end
    end

    context "when the user is a designer and discussion is with client" do
      it "returns the correct empty message for a designer" do
        html_output = helper.discussion_panel_empty_text("designer", "client")
        expect(html_output).to include("Kick off the conversation…")
        expect(html_output).to include("Chat with your client about their project here!")
      end
    end

    context "when the user is a client" do
      it "returns the correct empty message for a client is with client" do
        html_output = helper.discussion_panel_empty_text("client", "client")
        expect(html_output).to include("Chat with your designer here…")
        expect(html_output).to include("Ask a question, or just say hi!")
      end
    end
  end
end
