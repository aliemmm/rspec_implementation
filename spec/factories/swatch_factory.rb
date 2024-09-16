FactoryBot.define do
  factory :swatch do
    name { number.present? ? "#{number} #{Faker::Color.color_name}" : nil }
    family { Faker::Name.name }
    number { "#{SecureRandom.hex(2)}-#{SecureRandom.hex(2)}".upcase }
    hex { Faker::Color.hex_color }
    vendor { [0, 1, 2].sample }

    trait :archived do
      archived { true }
    end

    trait :deleted do
      deleted_at { Time.current }
    end

    trait :used do
      in_use { true }
    end
  end
end
