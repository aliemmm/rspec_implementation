require "rails_helper"

RSpec.describe Message do
  let(:project) { create(:project) }
  let(:board) { create(:board, project:) }
  let(:team) { project.team }
  let!(:client) { create(:user, :client, team:) }
  let(:comment) { Comment.new(project:, user: client, body: "Comment Body", commentable: project) }

  subject(:comment_message) { described_class.new(comment:) }

  describe "#project" do
    context "when dealing with a Project's Comment" do
      it { expect(comment_message.project).to eq(comment.project) }
    end

    context "when dealind with a Board's comment" do
      let(:comment) { Comment.new(project:, user: client, body: "Comment Body", commentable: board) }
      it { expect(comment_message.project).to eq(comment.project) }
    end
  end

  describe "#board" do
    context "when dealing with a Project's Comment" do
      it { expect(comment_message.board).to eq(nil) }
    end

    context "when dealing with a Board's comment" do
      let(:comment) { Comment.new(project:, user: client, body: "Comment Body", commentable: board) }
      it { expect(comment_message.board).to eq(comment.commentable) }
    end
  end

  describe "#text" do
    it { expect(comment_message.text).to eq(comment.body) }
  end

  describe "#sender" do
    it { expect(comment_message.sender).to eq(comment.user) }
  end

  describe "#created_at" do
    it { expect(comment_message.created_at).to eq(comment.created_at) }
  end

  describe "#images" do
    let(:item) { create(:item, :with_image, project: project) }
    before { comment.items << item }

    it { expect(comment_message.images.include?(item.image)) }
  end

  describe "#items" do
    let(:item) { create(:item, :with_image, project: project) }
    before { comment.items << item }

    it { expect(comment_message.items).to eq([item]) }
  end

  describe "#.to_partial_path" do
    it { expect(comment_message.to_partial_path).to eq("messages/message") }
  end

end
