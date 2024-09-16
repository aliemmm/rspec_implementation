require "rails_helper"

RSpec.describe FinancialsSummary do
  include described_class

  let(:team) { create(:team) }
  let(:designer) { create(:user, :designer, team:) }
  let(:project) { create(:project, designers: [designer]) }
  let(:vendor) { create(:vendor, team:) }

  describe "Get financial summary amounts" do
    describe "with invoices" do
      before do
        invoice = project.invoices.new(issue_date: Time.zone.today)
        invoice.invoice_items.build(unit_price: 50, kind: "line", markup: 0.2)
        invoice.invoice_items.build(unit_price: 50, kind: "line", markup: 0.3)
        invoice.save!
        invoice.invoice_payments.create!(amount: 10, ach_status: "succeeded")
      end

      it "returns total, paid, and balance amounts" do
        expect(financial_summary_amounts(project.invoices)).to eq([100.25, 10, 90.25, 0.25])
      end
    end

    context "with purchase orders" do
      before do
        purchase_order = project.purchase_orders.new(issue_date: Time.zone.today, vendor: vendor)
        purchase_order.purchase_order_items.build(unit_price: 100, kind: "line")
        purchase_order.save!
        purchase_order.purchase_order_payments.create!(amount: 10)
      end

      it "returns total, paid and balance amounts" do
        expect(financial_summary_amounts(project.purchase_orders)).to eq([100, 10, 90])
      end
    end

    context "with quotes" do
      before do
        quote = project.quotes.new(issue_date: Time.zone.today, status: "approved")
        quote.quote_items.build(unit_price: 100, kind: "line")
        quote.save!
      end

      it "returns total and approved amounts" do
        expect(financial_summary_amounts(project.quotes)).to eq([100, 100])
      end
    end

    context "with tracked time" do
      before do
        project.tracked_times.create!(user_id: designer.id, duration: 10.hours, hourly_rate: 10,
          invoiced: true)
        project.tracked_times
          .create!(
            user_id: designer.id,
            duration: 1.hour,
            hourly_rate: 10,
            invoiced: true,
            tracked_time_category: create(:tracked_time_category, team:, non_billable: true)
          )
      end

      it "returns billed duration, non billed duration, total and invoiced amounts" do
        expect(financial_summary_amounts(project.tracked_times)).to eq([10, 1, 100, 110])
      end
    end

    describe "with retainers" do
      before do
        retainer = project.retainers.new(issue_date: Time.zone.today)
        retainer.retainer_items.build(client_price: 100)
        retainer.save!
        retainer.retainer_payments.create!(amount: 100, ach_status: "succeeded")

        invoice = project.invoices.new(issue_date: Time.zone.today)
        invoice.invoice_items.build(unit_price: 100, kind: "line")
        invoice.save!
        invoice.invoice_payments.create!(amount: 80, ach_status: "succeeded", retainer:)
      end

      it "returns total, paid, and balance amounts" do
        expect(financial_summary_amounts(project.retainers)).to eq([100, 80, 20])
      end
    end
  end
end
