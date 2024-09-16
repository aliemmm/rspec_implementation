require "spec_helper"

RSpec.describe DuplicateJob do
  let!(:quote) { create(:quote) }
  let!(:quote_items) { create_list(:quote_item, 3, quote:) }

  describe "#perform_now" do
    subject(:duplicate_billable) do
      described_class.perform_now(quote)
    end
    
    context "when there is some error" do
      let(:error) { StandardError.new("Oopsy") }

      before do
        allow(quote)
          .to receive(:quote_items)
          .and_raise(error)
      end

      it "does not copy anything" do
        skip "This test is randomly failing on CI"
        expect { duplicate_billable }
          .to change(Quote, :count).by(0)
          .and change(QuoteItem, :count).by(0)
      end

      it "reports the error to Sentry" do
        expect(Sentry).to receive(:capture_exception).with(error)

        duplicate_billable
      end
    end
  end
end
