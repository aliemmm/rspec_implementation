def execute_invoice_past_due_task
  load(Rails.root.join("lib/tasks/invoices.rake").to_s, __FILE__)
  Rake::Task.define_task(:environment)
  Rake::Task["df:invoices:check_and_update_past_due_status"].invoke
end

RSpec.describe NotificationsController do
  let(:team) { create(:team) }
  let(:designer) { create(:user, :member, team:) }
  let(:project) { create(:project, designers: [designer]) }

  describe "GET index" do
    context "when logged as designer" do
      before do
        sign_in(designer)
      end

      context "with subtask assigned" do
        let!(:assigner) { create(:user, :designer, team:) }
        let(:task) { create(:task, team:, project:) }
        let!(:subtask) { create(:task, team:, project:, parent: task, assigner:, assignee: designer) }

        before do
          get notifications_path
        end

        it "has sub-task notification text" do
          response_as_text = Nokogiri::HTML(json_body["html"]).text.gsub(/\s+/, " ")

          expect(response_as_text).to include(
            "#{assigner.name} assigned you a sub-task on #{project.name}"
          )
        end

        it "has sub-task review link" do
          expect(json_body["html"]).to include(
            %(href="/tasks?project_id=#{project.id}&amp;subtask_id=#{subtask.id}&amp;task_id=#{task.id})
          )
        end
      end

      context "with assignment to project" do
        before do
          create(:user, :designer, team:)
          create(:notification, project:, kind: "designer-assigned-to-project", designer:)
        end

        it "shows a notification for the project assignment" do
          get notifications_path

          expect(response.body).to include "were assigned to the project"
        end
      end

      context "with past-due" do
        let(:designer) { create(:user, :designer, team:) }

        context "when project is not assigned" do
          let(:invoice) { create(:invoice, team:, project: nil, due_on: Date.yesterday, status: :submitted) }

          before do
            invoice

            execute_invoice_past_due_task

            get notifications_path
          end

          it "received correct notification text" do
            response_as_text = Nokogiri::HTML(json_body["html"]).text.gsub(/\s+/, " ")

            expect(response_as_text).to include(
              "Invoice #{invoice.invoice_id} is Past Due"
            )
          end
        end
      end
    end
  end
end
