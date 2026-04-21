class Cart < ApplicationRecord
  validates :total_price, numericality: { greater_than_or_equal_to: 0 }

  has_many :cart_items, dependent: :destroy

  def mark_as_abandoned = update(abandoned: true)

  def remove_if_abandoned
    destroy if abandoned_for_a_week_or_more?
  end

  def add_item(cart_item)
    modify_cart(cart_item) { |product_id:, quantity:| upsert_cart_item(product_id:, quantity:) }
  end

  def change_item_quantity(cart_item)
    if cart_item[:quantity].to_i.zero?
      errors.add(:quantity, 'Quantity can not be 0')
      return false
    end

    modify_cart(cart_item) { |product_id:, quantity:| update_cart_quantity_and_total_price(product_id:, quantity:) }
  end

  def remove_item(product_id)
    item = cart_items.find_by(product_id:)

    unless item
      errors.add(:product_id, 'Product not present in cart')
      return false
    end

    transaction do
      item.destroy!
      recalculate_total!
      update_last_interaction_at!
      destroy! if cart_items.reload.empty?
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
    errors.merge!(e.record.errors)
    false
  end

  private

    def modify_cart(cart_item)
      product_id = cart_item[:product_id]
      quantity   = cart_item[:quantity]

      transaction do
        yield(product_id:, quantity:)
        recalculate_total!
        update_last_interaction_at!
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      errors.merge!(e.record.errors)
      false
    end

    def abandoned_for_a_week_or_more?
      return false unless abandoned?

      last_interaction_at.before?(7.days.ago)
    end

    def upsert_cart_item(product_id:, quantity:)
      product = Product.find(product_id)
      cart_items.create!(product_id:, quantity:, total_price: product.price * quantity.to_i)
    end

    def update_cart_quantity_and_total_price(product_id:, quantity:)
      product = Product.find(product_id)
      item    = cart_items.find_by!(product_id:)
      new_quantity = item.quantity + quantity.to_i

      item.update!(quantity: new_quantity, total_price: product.price * new_quantity)
    end

    def recalculate_total!
      update!(total_price: cart_items.sum(:total_price))
    end

    def update_last_interaction_at!
      update!(last_interaction_at: Time.current)
    end
end
