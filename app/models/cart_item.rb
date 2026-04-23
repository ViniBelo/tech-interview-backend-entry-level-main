class CartItem < ApplicationRecord
  self.primary_key = [:cart_id, :product_id]

  validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :product_id, uniqueness: { scope: :cart_id }

  belongs_to :cart
  belongs_to :product
end
