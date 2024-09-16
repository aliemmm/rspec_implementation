FactoryBot.define do
  factory :invoice_item do
    invoice
    item factory: %i[item with_image]
    name { Faker::Name.name }
    tracked_times_duration { "all_uninvoiced" }
    unit_price { Faker::Number.decimal(l_digits: 2, r_digits: 3) }
    markup { 0 }
    tax { false }
    item_type { "service" }
    kind { "item" }

    trait :tracked_time do
      kind { "tracked_time" }
    end

    trait :refunded do
      refunded { true }
    end

    trait :with_image do
      transient do
        images { ["spec/support/files/chair.jpg"] }
      end

      image { Rack::Test::UploadedFile.new(Rails.root.join(images.shuffle!.pop)) }
    end
  end
end
