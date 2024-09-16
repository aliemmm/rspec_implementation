RSpec.describe TaskTemplate do
  let(:project) { create(:project, designers: [designer], created_by: designer) }
  let(:designer) { create(:user, :designer) }

  it { is_expected.to belong_to(:team) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to have_many(:tasks).dependent(:destroy) }

  it { is_expected.to validate_presence_of(:title) }

  it_behaves_like "paranoid model"

  describe ".add_template_tasks" do
    before do
      @task_template = create(:with_tasks_and_subtasks, team: designer.team, user: designer)
    end

    it "run add_template_tasks to create global tasks sub-tasks" do
      @task_template.add_template_tasks
      expect(designer.team.tasks.parents.not_templates.count).to eq(2)
      expect(designer.team.tasks.parents.not_templates.first.subtasks.count).to eq(2)
      expect(designer.team.tasks.parents.not_templates.last.subtasks.count).to eq(2)
    end

    it "run add_template_tasks to create project tasks sub-tasks" do
      @task_template.add_template_tasks(project.id)
      expect(project.tasks.parents.count).to eq(2)
      expect(project.tasks.parents.not_templates.first.subtasks.count).to eq(2)
      expect(project.tasks.parents.not_templates.last.subtasks.count).to eq(2)
    end
  end
end
