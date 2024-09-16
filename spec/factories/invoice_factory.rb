FactoryBot.define do
  factory :invoice do
    issue_date { Time.zone.today }
    project

    trait :refund do
      refund_invoice { true }
      original_invoice { association(:invoice) }
    end

    trait :pending do
      status { :pending }
    end

    trait :with_quickbooks do
      quickbooks_invoice_id { 1 }
      quickbooks_sync_status { 1 }
      quickbooks_sync { true }
      quickbooks_sync_error_message { nil }
      quickbooks_payment_id { 1 }
      quickbooks_sync_error_at { nil }
    end
  end
end
