FactoryBot.define do
  factory :product do
    transient do
      projects { [] }
    end

    sku { Faker::Lorem.unique.word }
    name { Faker::Name.name }
    store_url { Faker::Internet.url }
    price { Faker::Number.decimal(l_digits: 3, r_digits: 3) }
    retail_price { Faker::Number.decimal(l_digits: 3, r_digits: 3) }
    brand { Faker::Lorem.word }
  end
end
