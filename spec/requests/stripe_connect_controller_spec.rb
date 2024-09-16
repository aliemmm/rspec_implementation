RSpec.describe "StripeConnectController" do
  let(:team) { create(:team) }
  let(:designer) { create(:user, :designer, team:) }

  before { sign_in designer }

  describe "#authorize" do

    before do
      team.update!(
        stripe_connect_csrf_state: stripe_request_params[:state],
      )
    end

    let(:stripe_request_params) do
      {
        scope: "read_write",
        code: "safjlsdkjflksdjfljkkl",
        state: "aslheilsuiorueworiNZgDZXKzdDa126FJCzl4ETUkcVp8ThVTm6P8rg"
      }
    end

    it "updates the ach bank transfer flag accordingly" do
      skip "this test might fail if account gets disconnected"
      VCR.use_cassette("connect-team-to-stripe-connect", record: :new_episodes) do |cassette|
        travel_to_record_time(cassette)

        get authorize_stripe_connect_path, params: stripe_request_params

        expect(team.ach_bank_transfer_enabled).to be true
      end
    end
  end
end
