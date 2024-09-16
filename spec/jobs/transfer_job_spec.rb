RSpec.describe TransferJob do
  describe "#perform" do
    let(:project_ids) { [123] }
    let(:old_user_email) { "old_user@email.com" }
    let(:new_user_email) { "new_user@email.com" }
    let(:transfer_everything) { true }
    let(:email_send_to) { "send@to.email" }

    let(:params) { [project_ids, old_user_email, new_user_email, transfer_everything, email_send_to] }
    let(:service_instance) { instance_double(Projects::Transfer) }

    before do
      allow(service_instance).to receive(:call)
      allow(Projects::Transfer).to receive(:new).and_return(service_instance)

      described_class.new(*params).perform
    end

    it "transfer service to have initialized with correct params" do
      expect(Projects::Transfer).to have_received(:new).with(
        project_ids:, src_email: old_user_email, dest_email: new_user_email, transfer_everything:
      )
    end

    it "transfer service is called" do
      expect(service_instance).to have_received(:call)
    end
  end
end
