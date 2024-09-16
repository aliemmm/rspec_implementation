RSpec.describe Task do
  let(:project) { create(:project, designers: [designer], created_by: designer) }
  let(:assignee) { create(:user, team: designer.team, designer_role: :member) }
  let(:designer) { create(:user, :designer) }

  it { is_expected.to belong_to(:project).optional }
  it { is_expected.to belong_to(:assigner).class_name(User.name) }
  it { is_expected.to belong_to(:assignee).class_name(User.name).optional }
  it { is_expected.to belong_to(:parent).class_name(described_class.name).optional }

  it { is_expected.to define_enum_for(:priority).with_values(no_priority: 0, low: 10, medium: 20, high: 30) }

  it { is_expected.to validate_presence_of(:title) }

  it_behaves_like "paranoid model"

  describe ".search_tasks" do
    let!(:task) { create(:task, project:, team: designer.team) }

    it "returns tasks with matching title" do
      expect(described_class.search(task.title)).to contain_exactly(task)
    end

    it "returns tasks with matching notes" do
      expect(described_class.search(task.notes)).to contain_exactly(task)
    end

    it "returns tasks with matching title or notes in subtasks" do
      subtask = create(:task, title: "Best subtask ever", project:, team: designer.team, parent: task)
      expect(described_class.search("subtask")).to contain_exactly(task)
      expect(described_class.search("subtask")).not_to include([subtask])
    end

    it "returns tasks with matching title or notes in subtasks or matching maintask directly" do
      subtask = create(:task, title: "Best alavola subtask ever", project:, team: designer.team, parent: task)
      task2 = create(:task, title: "Best alavola task ever", project:, team: designer.team)

      expect(described_class.search("alavola")).to contain_exactly(task, task2)
      expect(described_class.search("alavola")).not_to include(subtask)
    end
  end

  describe ".for_user" do
    let!(:task) { create(:task, project:, team: designer.team) }
    let(:another_designer) { create(:user, :designer) }
    let(:client) { create(:user, :client, team: designer.team) }
    let!(:task2) { create(:task, project: nil, team: another_designer.team) }

    it "does not return anything for clients" do
      expect(described_class.for_user(client)).to be_empty
    end

    it "gets all the task of user team" do
      expect(described_class.for_user(designer)).to contain_exactly(task)
    end

    it "does not get other team tasks" do
      expect(described_class.for_user(another_designer)).to contain_exactly(task2)
    end
  end

  describe ".task_templates" do
    let!(:template_task) { create(:task, project:, team: designer.team, template: true) }
    let!(:task) { create(:task, project:, team: designer.team) }

    it "returns only template tasks" do
      expect(described_class.templates).to contain_exactly(template_task)
    end

    it "returns true for a template task" do
      expect(template_task).to be_template
    end

    it "returns false for a regular task" do
      expect(task).not_to be_template
    end
  end

  describe "#empty_notes_for_tasks" do
    it "cleans up empty tags for notes before validation" do
      task = described_class.new(project:, notes: "<p></p>", team: designer.team)
      task.valid?
      expect(task.notes).to eq("")
    end

    it "keeps non-empty html for notes" do
      task = described_class.new(project:, notes: "<p>Hello</p>", team: designer.team)
      task.valid?
      expect(task.notes).to eq("<p>Hello</p>")
    end

    it "keeps plain text for notes" do
      task = described_class.new(project:, notes: "hello", team: designer.team)
      task.valid?
      expect(task.notes).to eq("hello")
    end
  end

  describe "#set_sort_order" do
    let(:task) { create(:task, project:, team: designer.team) }

    context "first task of the project" do
      it "sets the order to 1" do
        expect(task.sort_order).to eq(1)
      end
    end

    context "5th task of the project" do
      before do
        create(:task, project:, team: designer.team)
        create(:task, project:, team: designer.team)
        create(:task, project:, team: designer.team)
        create(:task, project:, team: designer.team)
      end

      it "sets the order to 5" do
        expect(task.sort_order).to eq(5)
      end
    end
  end

  describe "#find_or_create_notification" do
    let!(:task) { create(:task, project:, assignee:, team: designer.team) }

    it "creates a notification of specified kind" do
      expect { task.find_or_create_notification("emi") }.to change(Notification, :count).by(1)
      notification = task.notifications.last

      expect(notification.kind).to eq("emi")
      expect(notification.task).to eq(task)
      expect(notification.project).to eq(task.project)
      expect(notification.designer).to eq(task.assignee)
      expect(notification.viewed).to be(false)
    end

    it "updates the existing notification with task update time" do
      expect { task.find_or_create_notification("emi") }.to change(Notification, :count).by(1)
      expect { task.find_or_create_notification("emi") }.not_to change(Notification, :count)

      expect(task.notifications.find_by(kind: "emi").created_at.to_s).to eq(task.updated_at.to_s)
    end

    it "creates notification for assigner if assignee is empty" do
      task = create(:task, project:, team: designer.team)
      task.find_or_create_notification("emi")

      expect(task.notifications.last.designer).to eq(task.assigner)
    end
  end

  describe "#create_and_send_notification" do
    it "creates a task notification and sends email" do
      expect do
        create(:task, project:, assignee:, team: designer.team)
      end.to change(Notification, :count)

      expect(assignee.notifications.pluck(:kind)).to include("task")

      email = ActionMailer::Base.deliveries.last
      expect(email.subject).to eq("Task Assigned to You")
      expect(email.to).to eq([assignee.email])
    end

    it "does not create task notification if assigned to self" do
      project
      expect { create(:task, project:, assigner: designer, assignee: designer, team: designer.team) }
        .not_to change(Notification, :count)
    end

    it "does not send email if assigned to self" do
      create(:task, project:, assigner: designer, assignee: designer, team: designer.team)

      expect(ActionMailer::Base.deliveries.last).to be_nil
    end

    it "does not send email if assignee is empty" do
      create(:task, project:, assignee: nil, team: designer.team)

      expect(ActionMailer::Base.deliveries.last).to be_nil
    end
  end

  describe "#create_task_completed_activity_log" do
    let!(:task) { create(:task, project:, team: designer.team) }

    it "creates a completed notification on task completion" do
      expect { task.update!(completed: true) }.to change(Notification, :count).by(1)
      expect(task.notifications.find_by(kind: "task-completed")).not_to be_nil
    end

    it "skips if the task has not been completed" do
      expect { task.update!(completed: false) }.not_to change(Notification, :count)
      expect(task.notifications.find_by(kind: "task-completed")).to be_nil
    end
  end

  describe "#update" do
    let!(:task) { create(:task, project:, team: designer.team) }
    let!(:subtask) { create(:task, title: "Subtask", project:, team: designer.team, parent: task) }
    let(:other_project) { create(:project, designers: [designer], created_by: designer) }

    it "propagates project reference to subtasks" do
      task.update!(project_id: other_project.id)

      expect(subtask.reload.project_id).to eq(other_project.id)
    end

    it "propagates global task status to subtasks" do
      task.update!(project_id: nil)

      expect(subtask.reload.project_id).to be_nil
    end
  end
end
