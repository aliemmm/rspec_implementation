FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "Tag ##{n}" }
    team
  end
end
