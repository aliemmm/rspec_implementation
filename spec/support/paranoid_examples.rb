RSpec.shared_examples "paranoid model" do
  it { is_expected.to have_db_column(:deleted_at) }

  it "has a scope to select soft-deleted records" do
    expect(described_class).to respond_to(:only_deleted)
  end

  it "has a scope to select both not-deleted and soft-deleted records" do
    expect(described_class).to respond_to(:with_deleted)
  end

  context "deleting an instance" do
    it "only soft-deletes the model when deleted" do
      subject.team = create(:team) if subject.team_id.blank?

      subject.destroy!

      expect(subject.deleted_at).not_to be_nil
    end
  end
end
