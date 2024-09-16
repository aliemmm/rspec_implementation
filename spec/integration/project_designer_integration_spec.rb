RSpec.describe "ProjectDesignerIntegration" do
  let(:project) { build(:project, designers: [designer]) }
  let(:team) { create(:team, :with_admin) }
  let(:designer) { team.admin }
  let(:new_designer) { create(:user, :member, team:) }

  describe "Project" do
    before { project.save! }

    it "saves the designer properly" do
      project_designer = project.project_designers.first

      expect(project.project_designers.count).to eq 1
      expect(project_designer.project).to eq project
      expect(project_designer.designer).to eq designer
    end

    describe "#designers" do
      it "includes the project designer" do
        expect(project.designers).to include designer
      end
    end

    describe "#designer" do
      it "returns the first designer" do
        expect(project.designer).to eq designer

        project.project_designers.delete_all

        expect(project.reload.designer).to be_nil
      end
    end

    describe "#designer_id" do
      it "returns the id of the first designer" do
        expect(project.designer_id).to eq designer.id

        project.project_designers.delete_all

        expect(project.reload.designer_id).to be_nil
      end
    end
  end
end
