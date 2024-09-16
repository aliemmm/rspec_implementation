RSpec.describe TaxRate do
  let(:team) { create(:team) }
  let!(:designer) { create(:user, :designer, team:) }
  let(:project) { create(:project, designers: [designer], created_by: designer) }
  let(:sales_tax) { create(:sales_tax, :with_tax_rates, team:) }

  describe "ensures tax rate cannot be changed" do
    it "if sales tax used in quote" do
      project.quotes.create!(issue_date: Time.zone.today, sales_tax:)
      tax_rate = sales_tax.reload.tax_rates.first

      tax_rate.rate = 9

      expect(tax_rate.valid?).to be false
      expect(tax_rate.errors.full_messages).to include("This sales tax cannot be changed because it is in use")
    end

    it "if sales tax used in invoice" do
      project.invoices.create!(issue_date: Time.zone.today, sales_tax:)
      tax_rate = sales_tax.reload.tax_rates.first

      tax_rate.rate = 9

      expect(tax_rate.valid?).to be false
      expect(tax_rate.errors.full_messages).to include("This sales tax cannot be changed because it is in use")
    end

    it "if sales tax used in purchase_order" do
      project.purchase_orders.create!(issue_date: Time.zone.today, sales_tax:)
      tax_rate = sales_tax.reload.tax_rates.first

      tax_rate.rate = 9

      expect(tax_rate.valid?).to be false
      expect(tax_rate.errors.full_messages).to include("This sales tax cannot be changed because it is in use")
    end

    it "if sales tax used in design_package" do
      create(:design_package, team_id: team.id, price: 100, covered_rooms_number: 0, sales_tax:,
        rooms: {"Family Room" => 1, "Nursery" => 1})
      tax_rate = sales_tax.reload.tax_rates.first

      tax_rate.rate = 9

      expect(tax_rate.valid?).to be false
      expect(tax_rate.errors.full_messages).to include("This sales tax cannot be changed because it is in use")
    end
  end

  describe "prevents in-use tax rate to be deleted" do
    it "if sales tax used in quote" do
      project.quotes.create!(issue_date: Time.zone.today, sales_tax:)
      tax_rate = sales_tax.reload.tax_rates.first

      expect { tax_rate.destroy }.not_to change(described_class, :count)
    end

    it "if sales tax used in invoice" do
      project.invoices.create!(issue_date: Time.zone.today, sales_tax:)
      tax_rate = sales_tax.reload.tax_rates.first

      expect { tax_rate.destroy }.not_to change(described_class, :count)
    end

    it "if sales tax used in purchase_order" do
      project.purchase_orders.create!(issue_date: Time.zone.today, sales_tax:)
      tax_rate = sales_tax.reload.tax_rates.first

      expect { tax_rate.destroy }.not_to change(described_class, :count)
    end

    it "if sales tax used in design_package" do
      create(:design_package, team_id: team.id, price: 100, covered_rooms_number: 0, sales_tax:,
        rooms: {"Family Room" => 1, "Nursery" => 1})
      tax_rate = sales_tax.reload.tax_rates.first

      expect { tax_rate.destroy }.not_to change(described_class, :count)
    end
  end
end
