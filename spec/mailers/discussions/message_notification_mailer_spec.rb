RSpec.describe Discussions::MessageNotificationMailer do
  describe "#notify_client_thread" do
    let(:team) { create(:team) }
    let!(:designer) { create(:user, :designer, team:) }
    let(:project) { create(:project, designers: [designer]) }
    let(:discussion) { Discussion.create(project:) }
    let(:message) { ::Message.new(text: Faker::Lorem.paragraph, sender: designer, discussion: discussion) }
    let!(:user) { create(:user, :client, team:) }

    before do
      project.designers = [designer]
      project.clients << user
    end

    subject(:mail) { described_class.notify_client_designer_thread(user:, message:) }

    it { expect(mail.subject).to eq("You have received a new message for #{project.name}") }
    it { expect(mail.to).to eq([user.email]) }
    it { expect(mail.from).to eq(["test@gmail.co"]) }
  end

  describe "#notify_team_thread" do
    let(:team) { create(:team) }
    let!(:designer) { create(:user, :designer, team:) }
    let(:project) { create(:project, designers: [designer]) }
    let(:discussion) { Discussion.create(project:, kind: :team) }
    let(:message) { ::Message.new(text: Faker::Lorem.paragraph, sender: designer, discussion: discussion) }
    let!(:other_designer) { create(:user, :member, team:) }

    before do
      project.designers = [designer, other_designer]
    end

    subject(:mail) { described_class.notify_team_thread(user: other_designer, message:) }

    it { expect(mail.subject).to eq("You have received a new team message for #{project.name}") }
    it { expect(mail.to).to eq([other_designer.email]) }
    it { expect(mail.from).to eq(["test@gmail.co"]) }
  end
end
