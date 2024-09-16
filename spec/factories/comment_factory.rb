FactoryBot.define do
  factory :comment do
    body { "comment" }
    user { association(:user, :designer) }

    for_board

    trait :for_board do
      commentable { association(:board) }
    end

    trait :for_fp_view do
      commentable { association(:fp_view) }
    end

    trait :for_task do
      commentable { association(:task) }
    end
  end
end
