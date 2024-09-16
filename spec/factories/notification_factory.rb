FactoryBot.define do
  factory :notification do
    designer { association(:user, :designer) }
  end
end
