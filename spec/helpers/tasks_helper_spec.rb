require "rails_helper"
require_relative "../support/controller_helper_methods"

RSpec.describe TasksHelper do
  before do
    helper.extend(ControllerHelperMethods)
  end

  describe "#task_assignee_options" do
    let(:current_team) do
      team = helper.current_team
      team.update! role_permissions: {member: []}
      team
    end

    let!(:designer) { create(:user, :designer, first_name: "Andy", team: current_team) }
    let!(:manager1) { create(:user, :manager, first_name: "Brian", team: current_team) }
    let!(:manager2) { create(:user, :manager, first_name: "Ciu", team: current_team) }
    let!(:member1) { create(:user, :member, first_name: "Dan", team: current_team) }
    let!(:member2) { create(:user, :member, first_name: "Erwin", team: current_team) }

    let(:project) { create(:project, designers: [designer], created_by: designer) }

    before { designer && current_team.reload }

    context "when the task is global" do
      let(:task) { create(:task, :global_task, team: current_team) }

      it "includes all team members" do
        expect(helper.task_assignee_options(task)).to eq([designer, manager1, manager2, member1, member2])
      end
    end
  end

  describe "#options_to_select_assignee" do
    let(:current_team) do
      team = helper.current_team
      team.update! role_permissions: {member: []}
      team
    end
    let(:designer) { create(:user, :designer, first_name: "Bubu", team: current_team) }
    let(:manager1) { create(:user, :manager, first_name: "Fabu", team: current_team) }
    let(:manager2) { create(:user, :manager, first_name: "Dubu", team: current_team) }
    let(:member1) { create(:user, :member, first_name: "Abu", team: current_team) }
    let(:member2) { create(:user, :member, first_name: "Chand", team: current_team) }
    let(:project) { create(:project, designers: [designer], created_by: designer) }
    let(:base_options) { [["Select", nil]] }

    let(:task) { Task.new(project:) }

    before { designer && current_team.reload }

    it "returns possible assignee options for the task" do
      options = base_options.concat [member1, designer, manager1].pluck(:name, :id)
      allow(helper).to receive(:options_for_select)

      helper.options_to_select_assignee(task)

      expect(helper).to have_received(:options_for_select).with(options, nil)
    end

    it "sets already assigned user as default" do
      options = base_options.concat [member1, designer, manager1].pluck(:name, :id)
      task.assignee = member1
      allow(helper).to receive(:options_for_select)

      helper.options_to_select_assignee(task)

      expect(helper).to have_received(:options_for_select).with(options, member1.id)
    end

    it "does not show a select option if one option available" do
      options = [["Select", nil], [designer.name, designer.id]]
      allow(helper).to receive(:options_for_select)

      helper.options_to_select_assignee(task)

      expect(helper).to have_received(:options_for_select).with(options, nil)
    end

    it "orders possible options by user name" do
      options = base_options.concat [member1, designer, member2, manager2, manager1].pluck(:name, :id)
      allow(helper).to receive(:options_for_select)

      helper.options_to_select_assignee(task)

      expect(helper).to have_received(:options_for_select).with(options, nil)
    end

    it "includes team admin and managers + many project members" do
      designer_2 = create(:user, :designer, designer_role: "member", first_name: "Brian", team: current_team)
      task.project.designers << designer_2

      options = base_options.concat [designer_2, designer, manager2, manager1].pluck(:name, :id)
      allow(helper).to receive(:options_for_select)

      helper.options_to_select_assignee(task)

      expect(helper).to have_received(:options_for_select).with(options, nil)
    end

    context "when the task is global" do
      let(:task) { create(:task, :global_task, team: current_team) }

      before do
        member1
        designer
        member2
        manager2
        manager1
      end

      it "includes all team members" do
        options = base_options.concat [member1, designer, member2, manager2, manager1].pluck(:name, :id)
        allow(helper).to receive(:options_for_select)

        helper.options_to_select_assignee(task)

        expect(helper).to have_received(:options_for_select).with(options, nil)
      end
    end

    context "when the task belongs to a project AND team has show-only-assigned-projects permission set" do
      before do
        current_team.update! role_permissions: {member: ["show-only-assigned-projects"]}
      end

      it "includes admin" do
        options = [["Select", nil], [designer.name, designer.id]]
        allow(helper).to receive(:options_for_select)

        helper.options_to_select_assignee(task)

        expect(helper).to have_received(:options_for_select).with(options, nil)
      end

      it "includes managers" do
        options = base_options.concat [designer, manager2, manager1].pluck(:name, :id)
        allow(helper).to receive(:options_for_select)

        helper.options_to_select_assignee(task)

        expect(helper).to have_received(:options_for_select).with(options, nil)
      end

      it "includes project designer" do
        project = create(:project, designers: [manager1], created_by: designer)
        task = Task.new(project:)
        options = base_options.concat [designer, manager2, manager1].pluck(:name, :id)
        allow(helper).to receive(:options_for_select)

        helper.options_to_select_assignee(task)

        expect(helper).to have_received(:options_for_select).with(options, nil)
      end

      it "does not include regular members" do
        member1
        member2
        options = [["Select", nil], [designer.name, designer.id]]
        allow(helper).to receive(:options_for_select)

        helper.options_to_select_assignee(task)

        expect(helper).to have_received(:options_for_select).with(options, nil)
      end
    end
  end

  describe "#priority_tag_class" do
    %w[low medium high].each do |priority|
      it "get formatted class name for known priority #{priority}" do
        expect(helper.priority_tag_class(priority)).to eq("task-priority__tag--#{priority}")
      end
    end

    it "does not return any class name for known no_priority" do
      expect(helper.priority_tag_class("no_priority")).to be_nil
    end

    it "does not return any class name for unknown options" do
      expect(helper.priority_tag_class("xxx")).to be_nil
    end
  end

  describe "#priority_options" do
    let(:humanized_options) do
      [["No priority", "no_priority"], %w[Low low], %w[Medium medium], %w[High high]]
    end

    it "returns a list with humanized names" do
      expect(helper.priority_options).to match_array(humanized_options)
    end
  end
end
