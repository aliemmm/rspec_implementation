FactoryBot.define do
  factory :task do
    project
    assigner factory: %i[user designer]
    title { Faker::Lorem.sentence }

    trait :with_due_date do
      due_date { Date.parse("07/03/2023") }
    end

    trait :incomplete_task do
      with_due_date
    end

    trait :completed_task do
      with_due_date
      completed { true }
    end

    trait :yesterday_completed_task do
      due_date { Date.current - 1.day }
      completed { true }
    end

    trait :global_task do
      project { nil }
    end
  end
end
