RSpec.describe "TaskTemplatesController" do
  let(:team) { create(:team) }
  let(:designer) { create(:user, :designer, team:) }
  let(:task_template) { create(:task_template, team:, user: designer) }

  before do
    sign_in designer
  end

  describe "GET #index" do
    before do
      get task_templates_path
    end

    it "assigns task_templates" do
      expect(assigns(:task_templates)).to eq(team.task_templates)
    end

    it "renders the index template" do
      expect(response).to render_template(:index)
    end
  end

  describe "GET #new" do
    it "renders the task template form partial" do
      get new_task_template_path
      expect(response).to render_template(partial: "_modal--task-template-form")
    end
  end

  describe "POST #create" do
    before do
      @template_name = Faker::Lorem.sentence
      post task_templates_path, params: {title: @template_name}
    end

    it "creates a new task template" do
      expect(TaskTemplate.count).to eq(1)
    end

    it "redirects to task_templates_path" do
      template_task = TaskTemplate.last
      expect(response).to redirect_to(edit_task_template_path(template_task))
    end

    it "sets a flash notice" do
      expect(flash[:notice]).to eq("#{@template_name} was successfully saved as Task Template")
    end
  end

  describe "PATCH #update" do
    before do
      @template_name = Faker::Lorem.sentence
      patch task_template_path(task_template), params: {task_template: {title: @template_name}}
      task_template.reload
    end

    it "update the task template title" do
      expect(@template_name).to eq(task_template.title)
    end

    it "redirects to task_templates_path" do
      expect(response).to redirect_to(task_templates_path)
    end

    it "sets a flash notice" do
      expect(flash[:notice]).to eq("You have successfully updated #{@template_name} Task Template")
    end
  end

  describe "DELETE #destroy" do
    before do
      delete task_template_path(task_template)
    end

    it "destroys the task template" do
      expect(TaskTemplate.count).to eq(0)
    end

    it "redirects to task_templates_path" do
      expect(response).to redirect_to(task_templates_path)
    end

    it "sets a flash notice" do
      expect(flash[:notice]).to eq("You have successfully deleted #{task_template.title} Task Template")
    end
  end
end
