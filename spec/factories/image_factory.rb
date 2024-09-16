FactoryBot.define do
  factory :image do
    transient do
      images { ["spec/support/files/chair.jpg"] }
    end

    kind { :additional_image }
    image { Rack::Test::UploadedFile.new(Rails.root.join(images.sample)) }
    item { nil }
    product { nil }
    team { nil }
    questionnaire { nil }
  end
end
