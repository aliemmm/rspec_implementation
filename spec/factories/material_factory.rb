FactoryBot.define do
  factory :material do
    root { false }
    name { Faker::Beer.style }

    trait :paint do
      kind { "paint" }
      swatch { association(:swatch, strategy: :build) }

      name { swatch.name }
      swatch_number { swatch.number }
      color { swatch.hex }
    end

    Material.kinds.keys.excluding("paint").each do |kind|
      trait kind do
        kind { kind }
        subcategory { Faker::Beer.style }
        image do
          images = Dir[Rails.root.join("spec/support/files/materials/*")]
          Rack::Test::UploadedFile.new(images.sample)
        end
      end
    end

    trait :root do
      root { true }
    end
  end
end
