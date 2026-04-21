FactoryBot.define do
  factory :cart, aliases: [:shopping_cart] do
    total_price { 0.0 }
  end
end
