FactoryBot.define do
  factory :invoice_payment do
    invoice
    amount { invoice.total }
    payment_method { "bank_transfer" }
    date { Time.zone.now.to_date }
  end
end
