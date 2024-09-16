RSpec.describe Address do
  context "associations" do
    it { is_expected.to belong_to(:vendor).optional }
  end

  context "validations" do
    shared_examples "allows only one relation" do |relation, error = "#{relation.to_s.humanize} can has only 1 address."|
      subject { existing_address.dup }
      let!(:existing_address) { create(:address, relation => record) }

      it "allows only one address for #{relation}" do
        expect(subject.valid?).to eq(false)
        expect(subject.errors.full_messages).to include(error)
      end
    end

    it_behaves_like "allows only one relation", :vendor do
      let(:record) { create(:vendor) }
    end

    it_behaves_like "allows only one relation", :user do
      let(:record) { create(:user) }
    end
  end
end
