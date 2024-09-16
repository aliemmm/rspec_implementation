RSpec.shared_examples "validates and downcases email" do
  it { is_expected.not_to allow_value("test").for(:email) }
  it { is_expected.not_to allow_value("test @ test.com").for(:email) }
  it { is_expected.to allow_value("test@test.com").for(:email) }

  it "performs downcase after validation" do
    subject.email = "FoO@BaR.coM"
    expect(subject.tap(&:valid?).email).to eq("foo@bar.com")
  end
end
