FactoryBot.define do
  factory :calendar_event do
    title { Faker::Name.name }
    starts_at { Time.current }
    ends_at { Time.current }

    trait :all_day_single_day do
      starts_at { Time.zone.parse("03/03/2023") }
      ends_at { Time.zone.parse("03/03/2023") }
    end

    trait :all_day_multiday do
      starts_at { Time.zone.parse("03/03/2023") }
      ends_at { Time.zone.parse("07/03/2023") }
    end

    trait :non_all_day_same_day do
      all_day { false }
      starts_at { Time.zone.parse("03/03/2023 00:00") }
      ends_at { Time.zone.parse("03/03/2023 01:00") }
    end

    trait :non_all_day_multiday do
      all_day { false }
      starts_at { Time.zone.parse("03/03/2023 00:00") }
      ends_at { Time.zone.parse("07/03/2023 01:00") }
    end

    trait :yesterday do
      starts_at { Time.current.ago(1.day) }
      ends_at { Time.current.ago(1.day) }
    end
  end
end
