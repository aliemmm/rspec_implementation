FactoryBot.define do
  factory :message do
    text { Faker::Lorem.paragraph }
    user
    discussion
  end
end
