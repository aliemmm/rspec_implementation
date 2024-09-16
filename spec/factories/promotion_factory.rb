FactoryBot.define do
  factory :promotion do
    transient do
      duration { 3.days }
    end

    sequence(:title) { |n| "Promotion ##{n}" }
    sequence(:starts_at) { |n| n.days.since + (duration * n) }
    ends_at { starts_at + duration }
  end
end
