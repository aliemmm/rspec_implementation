FactoryBot.define do
  factory :project do
    team { designers.first.team }
    created_by { designers.first }
    budget_from { Faker::Number.number(digits: 4) }
    budget_to { Faker::Number.number(digits: 4) }
    notification_sent { false }
    name { Faker::Name.name }

    trait :archived do
      status { "archived" }
    end

    trait :accepted do
      accepted { true }
    end

    trait :active do
      accepted { true }
      sample { false }
    end
  end
end
