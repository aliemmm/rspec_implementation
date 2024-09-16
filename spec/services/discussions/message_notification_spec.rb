require "rails_helper"

RSpec.describe Discussions::MessageNotification do
  let(:team) { create(:team) }
  let!(:designer) { create(:user, :designer, team:) }
  let(:project) { create(:project, designers: [designer]) }
  let(:discussion) { Discussion.create(project:) }
  let(:message) { Message.create(text: Faker::Lorem.paragraph, sender: sender, discussion: discussion) }
  let!(:client) { create(:user, :client, team:) }
  let!(:base_queue_adapter) { ActiveJob::Base.queue_adapter }

  before do
    project.designers = [designer]
    project.clients << client
    ActiveJob::Base.queue_adapter = :test
  end

  after do
    ActiveJob::Base.queue_adapter = base_queue_adapter
  end

  describe "#notify" do
    subject(:message_notification) { described_class.new(message:) }

    context "when sender is the designer" do
      let(:sender) { designer }

      it "sends a notification to the client only" do
        expect { message_notification.call }
          .to enqueue_mail(Discussions::MessageNotificationMailer, :notify_client_designer_thread)
          .with(user: client, message:)

        expect { message_notification.call }
          .not_to enqueue_mail(Discussions::MessageNotificationMailer, :notify_client_designer_thread)
          .with(user: designer, message: message)
      end
    end

    context "when sender is the client" do
      let(:sender) { client }

      it "sends a notification to the designer only" do
        expect { message_notification.call }
          .to enqueue_mail(Discussions::MessageNotificationMailer, :notify_client_designer_thread)
          .with(user: designer, message: message)

        expect { message_notification.call }
          .not_to enqueue_mail(Discussions::MessageNotificationMailer, :notify_client_designer_thread)
          .with(user: client, message:)
      end
    end

    context "when discussion is limited to the team" do
      let(:discussion) { Discussion.create(project:, kind: :team) }
      let(:other_designer) { create(:user, :member, team:) }
      let(:sender) { other_designer }

      before do
        project.designers << other_designer
      end

      it "sends a notification to the recipient designer only" do
        expect { message_notification.call }
          .to enqueue_mail(Discussions::MessageNotificationMailer, :notify_team_thread)
          .with(user: designer, message: message)

        expect { message_notification.call }
          .not_to enqueue_mail(Discussions::MessageNotificationMailer, :notify_team_thread)
          .with(user: other_designer, message: message)
      end
    end
  end
end
