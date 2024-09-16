FactoryBot.define do
  factory :sales_tax do
    name { Faker::Name.name }
    rate { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
    team

    trait :with_tax_rates do
      after(:create) do |sales_tax, _evaluator|
        create_list(:tax_rate, 2, sales_tax:)
      end
    end
  end

  factory :tax_rate do
    name { Faker::Name.name }
    agency_name { Faker::Name.name }
    rate { Faker::Number.decimal(l_digits: 2, r_digits: 2) }
  end
end
