RSpec.describe Comment do
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:project).optional }
  it { is_expected.to belong_to(:commentable) }

  it { is_expected.to have_many(:notifications).dependent(:destroy) }
  it { is_expected.to have_many(:items).dependent(:destroy) }
  it { is_expected.to have_many(:user_comments) }
  it { is_expected.to have_many(:mentioned_users).through(:user_comments).source(:user) }

  it { is_expected.to validate_presence_of(:body) }

  it { is_expected.to define_enum_for(:kind).with_values(public_reply: 0, private_note: 1, task_public_comment: 2) }
  it { is_expected.to respond_to(:team) }

  describe "#task_comment?" do
    it "is true if commented on a task" do
      expect(Task.new.comments.new.task_comment?).to be true
    end

    it "is false if commented on a Board" do
      expect(Board.new.comments.new.task_comment?).to be false
    end
  end

  describe "after create" do
    describe "notifications" do
      let(:project) { create(:project) }
      let(:team) { project.team }
      let!(:client) { create(:user, :client, team:) }
      let!(:board) { create(:board, project:) }
      let!(:member) { create(:user, :member, team:) }
      let(:comment) { Comment.new(project:, user: client, body: "Comment Body", commentable: board) }
      let(:notifications) { Notification.where(kind: "comment-public-reply") }

      before do
        project.designers << member
      end

      it "creates notification for all project designers" do
        expect do
          comment.save!
        end.to change(Notification, :count).by(2)
      end

      it "created notifications have same group id", :aggregate_failures do
        comment.save!
        first_group_id, second_group_id = notifications.pluck(:group_id)

        expect(first_group_id).not_to be_nil
        expect(first_group_id).to eq(second_group_id)
      end

      # FIXME: flaky, should've been fixed in https://github.com/designfiles-co/df/pull/4679
      #   you can safely remove this comment after 30.08.24 if it's not an issue anymore
      it "notification is delivered to correct users" do
        comment.save!

        expect(notifications.pluck(:user_id)).to contain_exactly(project.designer.id, member.id)
      end
    end
  end
end
