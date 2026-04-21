class Cart < ApplicationRecord
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  has_many :cart_items, dependent: :destroy

  def mark_as_abandoned = update(abandoned: true)

  def remove_if_abandoned
    destroy if abandoned_for_a_week_or_more?
  end

  def add_item(cart_item)
    product_id = cart_item[:product_id]
    quantity   = cart_item[:quantity]

    transaction do
      upsert_cart_item(product_id:, quantity:)
      recalculate_total!
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.merge!(e.record.errors)
    false
  end

  private

    def abandoned_for_a_week_or_more?
      return false unless abandoned?

      last_interaction_at.before?(7.days.ago)
    end

    def upsert_cart_item(product_id:, quantity:)
      product = Product.find(product_id)
      cart_items.create!(product_id:, quantity:, total_price: product.price * quantity.to_i)
    end

    def recalculate_total!
      update!(total_price: cart_items.sum(:total_price))
    end
end
