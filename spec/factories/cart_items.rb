FactoryBot.define do
  factory :cart_item do
    association :cart
    association :product
    quantity { 1 }
    total_price { 0.0 }
  end
end
