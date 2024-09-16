FactoryBot.define do
  factory :team do
    name { Faker::Name.unique.name }
    hsr { "not_applicable" }
    role { "interior_designer_decorator" }
    size { "5to10" }
    tools { ["team_create_floor_plans_and_moodboards"] }
    hear_about { "recommended" }

    trait :with_admin do
      admin { association(:user, :designer, team: instance) }
    end


  end
end
