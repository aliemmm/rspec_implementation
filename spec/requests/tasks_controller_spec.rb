RSpec.describe "TasksController" do
  let(:team) { create(:team, time_zone: "Pacific Time (US & Canada)") }
  let(:designer) { create(:user, :designer, team:) }
  let(:assignee) { create(:user, :member, team:) }
  let(:project) { create(:project, designers: [designer], created_by: designer, id: 13) }
  let(:task_template) { create(:task_template, team:, user: designer) }

  describe "POST /create" do
    context "when a due date is NOT set" do
      it "does NOT schedule an email reminder" do
        task = create(:task, id: 17, project:, team:)

        expect do
          patch task_path(task), params: {task: {title: "Update title"}, view_context: :tasks}
        end.not_to(change { Delayed::Job.where("handler like '%task_due_today%'").count })
      end
    end
  end

  describe "PATCH /update" do
    before { sign_in designer }

    context "when a due date is set" do
      it "schedules an email reminder" do
        task = create(:task, id: 17, project:, team:)

        expect do
          patch task_path(task),
            params: {task: {due_date: "10/30/2020", assignee_id: assignee.id}, view_context: :tasks}
        end.to change { Delayed::Job.where("handler like '%task_due_today%'").count }.by(1)

        delayed_job = Delayed::Job.find(task.reload.due_today_email_delayed_job_id)
        expect(delayed_job.handler).to include("NotifierMailer")
        expect(delayed_job.handler).to include("task_due_today")
        expect(delayed_job.run_at).to eq(Time.zone.parse("2020-10-30 05:00:00 -0700"))
      end

      it "reschedules any existing email reminders" do
        task = create(:task, id: 17, project:, assignee:, team:, due_date: "2020-06-15")

        expect do
          patch task_path(task),
            params: {task: {due_date: "06/20/2020", assignee_id: assignee.id}, view_context: :tasks}
        end.not_to(change { Delayed::Job.where("handler like '%task_due_today%'").count })

        delayed_job = Delayed::Job.find(task.reload.due_today_email_delayed_job_id)
        expect(delayed_job.handler).to include("NotifierMailer")
        expect(delayed_job.handler).to include("task_due_today")
        expect(delayed_job.run_at).to eq(Time.zone.parse("2020-06-20 05:00:00 -0700"))
      end
    end

    context "when a due date is NOT set" do
      it "unschedules any email reminders" do
        task = create(:task, id: 17, project:, assignee:, team:, due_date: "2020-06-15")

        expect(task.due_today_email_delayed_job_id).not_to be_nil

        patch task_path(task), params: {task: {due_date: nil, assignee_id: assignee.id}, view_context: :tasks}

        expect(task.reload.due_today_email_delayed_job_id).to be_nil
      end
    end
  end

  describe "GET /task_templates/:id/edit task template tasks" do
    before { sign_in designer }

    context "when no tasks for task template are added" do
      it "get the tasks count for task template" do
        get edit_task_template_path(task_template)

        expect(assigns(:tasks).count).to eq 0
      end
    end

    context "when tasks for task template are added" do
      it "get the tasks count for task template" do
        create(:task, id: 17, task_template:, template: true, team:, project: nil)
        get edit_task_template_path(task_template)

        expect(assigns(:tasks).count).to eq 1
      end
    end
  end

  describe "GET /tasks in grid view" do
    before { sign_in designer }

    context "when team is on legacy plan" do
      before do
        allow(team).to receive(:legacy_plan?).and_return(true)
      end

      it "redirects to upgrade page" do
        get tasks_path

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(legacy_upgrade_path(feature: "tasks"))
      end
    end

    context "when team is on full service plan" do
      before do
        allow(team).to receive(:legacy_plan?).and_return(false)
      end

      it "allows user to use the tasks feature" do
        get tasks_path, params: {view_mode: :grid}

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end

    context "when designer team has tasks" do
      it "get the tasks count for team" do
        create(:task, id: 17, project:, assignee:, team:)
        create(:task, id: 18, project:, assignee: designer, team:)
        create(:task, id: 19, project:, assignee: designer, team:)

        get tasks_path, params: {view_mode: :grid}

        expect(assigns(:tasks).count).to eq 3
      end
    end
  end

  describe "POST #create" do
    before { sign_in designer }

    let(:task_params) { {title: "New Task", team:} }

    context "when @project is present" do
      before do
        post tasks_path, params: {task: task_params, project_id: project.id, view_context: :tasks}
      end

      it "creates a task with assigner_id as current_designer.id" do
        expect(Task.last.assigner_id).to eq(designer.id)
      end

      it "creates a task associated with the team" do
        expect(Task.last.team).to eq(team)
      end

      it "creates a task with the correct attributes" do
        task = Task.last
        expect(task.title).to eq(task_params[:title])
        expect(task.completed).to be(false)
      end

      it "persists the task to the database" do
        expect(Task.count).to eq(1)
      end
    end

    context "when @project is not present" do
      before do
        post tasks_path, params: {task: task_params, view_context: :tasks}
      end

      it "creates a task with assigner_id as current_designer.id" do
        expect(Task.last.assigner_id).to eq(designer.id)
      end

      it "creates a task not associated with any project" do
        expect(Task.last.project).to be_nil
      end

      it "creates a task associated with the team" do
        expect(Task.last.team).to eq(team)
      end

      it "persists the task to the database" do
        expect(Task.count).to eq(1)
      end
    end
  end

  describe "DELETE #destroy" do
    before { sign_in designer }

    context '"when request is xhr"' do
      let(:task) { create(:task, id: 17, project:, assignee:, team:, due_date: "2020-06-15") }

      before do
        delete task_path(task), xhr: true
      end

      it "destroys the task" do
        expect(Task.exists?(task.id)).to be(false)
      end

      it "returns a success JSON response" do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('"success":true')
      end

      it "decreases the count of the Task model" do
        expect(Task.count).to eq(0)
      end
    end

    context "when request is not xhr and it is a project task" do
      let(:task) { create(:task, project:, assignee:, team:, due_date: "2020-06-15") }

      before do
        delete task_path(task), params: {view_context: :projects, project_id: project.id}
      end

      it "destroys the task" do
        expect(Task.exists?(task.id)).to be(false)
      end

      it "redirects to the tasks or project_tasks path with a notice" do
        expect(response).to redirect_to(tasks_path(project_id: project.id, view_context: :projects))
        expect(flash[:notice]).to eq("You have successfully deleted the task.")
      end
    end

    context "when request is for global tasks" do
      let(:task) { create(:task, project:, assignee:, team:, due_date: "2020-06-15") }

      before do
        delete task_path(task), params: {view_context: :tasks}
      end

      it "destroys the task" do
        expect(Task.exists?(task.id)).to be(false)
      end

      it "redirects to the tasks or project_tasks path with a notice" do
        expect(response).to redirect_to(tasks_path(view_context: :tasks))
        expect(flash[:notice]).to eq("You have successfully deleted the task.")
      end

      it "decreases the count of the Task model" do
        expect(Task.count).to eq(0)
      end
    end
  end

  describe "GET /tasks filtered global tasks in grid view" do
    before { sign_in designer }

    let!(:high_priority_task) { create(:task, project:, assignee:, team:, priority: "high") }
    let!(:medium_priority_task) { create(:task, project:, assignee: designer, team:, priority: "medium") }
    let!(:low_priority_task) { create(:task, project:, assignee:, team:, priority: "low") }
    let!(:no_priority_task) { create(:task, project:, assignee: designer, team:, priority: "no_priority") }

    context "when high priority filter is selected" do
      before do
        get tasks_path, params: {priority: :high, view_mode: :grid}
      end

      it "filters tasks by high priority" do
        expect(assigns(:tasks)).to include(high_priority_task)
        expect(assigns(:tasks)).not_to include(medium_priority_task, low_priority_task, no_priority_task)
      end
    end

    context "when medium priority filter is selected" do
      before do
        get tasks_path, params: {priority: :medium, view_mode: :grid}
      end

      it "filters tasks by medium priority" do
        expect(assigns(:tasks)).to include(medium_priority_task)
        expect(assigns(:tasks)).not_to include(high_priority_task, low_priority_task, no_priority_task)
      end
    end

    context "when low priority filter is selected" do
      before do
        get tasks_path, params: {priority: :low, view_mode: :grid}
      end

      it "filters tasks by low priority" do
        expect(assigns(:tasks)).to include(low_priority_task)
        expect(assigns(:tasks)).not_to include(high_priority_task, medium_priority_task, no_priority_task)
      end
    end

    context "when no_priority filter is selected" do
      before do
        get tasks_path, params: {priority: :no_priority, view_mode: :grid}
      end

      it "filters tasks by no_priority" do
        expect(assigns(:tasks)).to include(no_priority_task)
        expect(assigns(:tasks)).not_to include(high_priority_task, medium_priority_task, low_priority_task)
      end
    end

    context "when designer filter is selected" do
      before do
        get tasks_path, params: {designer_id: designer.id, view_mode: :grid}
      end

      it "filters tasks by designer" do
        expect(assigns(:tasks)).to include(medium_priority_task, no_priority_task)
        expect(assigns(:tasks)).not_to include(high_priority_task, low_priority_task)
      end

      it "assigns @designer_name" do
        expect(assigns(:designer_name)).to eq(designer.name)
      end
    end

    context "with subtasks" do
      context "when designer filter is selected" do
        let(:task_with_subtask) { create(:task, project:, assignee: nil, team:, priority: "no_priority") }

        before do
          create(:task, parent: task_with_subtask, project:, assignee: designer, team:, priority: "no_priority")
        end

        it "filters parent tasks by designer assigned to subtask" do
          get tasks_path, params: {designer_id: designer.id, view_mode: :grid}

          expect(assigns(:tasks)).to include(task_with_subtask)
        end
      end
    end

    context "when project filter is selected" do
      let(:project2) { create(:project, designers: [designer], created_by: designer) }
      let!(:task) { create(:task, project: project2, team:, priority: "no_priority") }

      before do
        get tasks_path, params: {project_id: project2.id, view_mode: :grid}
      end

      it "filters tasks by project" do
        expect(assigns(:tasks)).to include(task)
        expect(assigns(:tasks)).not_to include(high_priority_task, medium_priority_task, low_priority_task,
          no_priority_task)
      end

      it "assigns @project_name" do
        expect(assigns(:project_name)).to eq(project2.name)
      end
    end

    context "when clearing priority filter" do
      before do
        get tasks_path, params: {priority: nil, view_mode: :grid}
      end

      it "clears the priority filter" do
        expect(assigns(:tasks)).to include(high_priority_task, low_priority_task, medium_priority_task,
          no_priority_task)
      end
    end

    context "when clearing designer filter" do
      before do
        get tasks_path, params: {designer_id: nil, view_mode: :grid}
      end

      it "clears the designer filter" do
        expect(assigns(:tasks)).to include(high_priority_task, medium_priority_task, low_priority_task,
          no_priority_task)
      end
    end

    context "when clearing project filter" do
      before do
        get tasks_path, params: {project_id: nil, view_mode: :grid}
      end

      it "clears the project filter" do
        expect(assigns(:tasks)).to include(high_priority_task, medium_priority_task, low_priority_task,
          no_priority_task)
      end
    end

    context "when clearing all filters" do
      before do
        get tasks_path, params: {priority: nil, designer_id: nil, project_id: nil, view_mode: :grid}
      end

      it "clears all filters" do
        expect(assigns(:tasks)).to include(high_priority_task, medium_priority_task, low_priority_task,
          no_priority_task)
      end
    end
  end

  describe "GET /tasks project tasks in grid view" do
    let(:project_id) { project.id }
    let(:view_context) { :projects }

    context "when designer is logged in" do
      before { sign_in designer }

      it "renders the tasks" do
        get tasks_path, params: {project_id:, view_context:, view_mode: :grid}

        expect(response).to have_http_status(:ok)
        expect(response).to render_template("tasks/_projects_tasks--grid")
      end

      it "assigns the necessary instance variables" do
        get tasks_path, params: {project_id:, view_context:, view_mode: :grid}

        expect(assigns(:project)).to eq(project)
        expect(assigns(:title)).to eq("Tasks - #{project.name}")
      end
    end

    context "when designer is not logged in" do
      it "redirects to the login page" do
        get tasks_path, params: {project_id:, view_context:}

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when team is on legacy plan" do
      before do
        sign_in designer
        allow(team).to receive(:legacy_plan?).and_return(true)
      end

      it "redirects to upgrade page" do
        get tasks_path, params: {project_id:, view_context: :projects}

        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(legacy_upgrade_path(feature: "tasks"))
      end
    end

    context "when team is on full service plan" do
      before do
        sign_in designer
        allow(team).to receive(:legacy_plan?).and_return(false)
      end

      it "allows user to use the tasks feature" do
        get tasks_path, params: {project_id:, view_context:, view_mode: :grid}

        expect(response).to have_http_status(:ok)
        expect(response).to render_template("tasks/_projects_tasks--grid")
      end
    end
  end
end
