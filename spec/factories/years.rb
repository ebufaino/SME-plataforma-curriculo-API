FactoryBot.define do
  factory :year do
    name { Faker::Lorem.sentence 4 }
    association :stage, factory: :stage
    association :segment, factory: :segment
  end
end
