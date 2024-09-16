FactoryBot.define do
  factory :designer_invite do
    sequence(:email) { |n| "invitee#{n}@example.com" }
    designer_role { DesignerInvite.designer_roles.keys.sample }

    user
    team { user.team }
  end
end
