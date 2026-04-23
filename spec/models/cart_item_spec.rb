require 'rails_helper'

RSpec.describe CartItem, type: :model do
  context 'when validating' do
    it 'is valid with a cart, a product, and a positive integer quantity' do
      cart_item = create(:cart_item)
      expect(cart_item.valid?).to be_truthy
    end

    it 'validates presence of cart' do
      cart_item = build(:cart_item, cart: nil)
      expect(cart_item.valid?).to be_falsey
      expect(cart_item.errors[:cart]).to include("must exist")
    end

    it 'validates presence of product' do
      cart_item = build(:cart_item, product: nil)
      expect(cart_item.valid?).to be_falsey
      expect(cart_item.errors[:product]).to include("must exist")
    end

    it 'validates quantity is an integer greater than or equal to 1' do
      cart_item = build(:cart_item, quantity: 0)
      expect(cart_item.valid?).to be_falsey
      expect(cart_item.errors[:quantity]).to include("must be greater than or equal to 1")
    end

    it 'validates quantity is not negative' do
      cart_item = build(:cart_item, quantity: -1)
      expect(cart_item.valid?).to be_falsey
      expect(cart_item.errors[:quantity]).to include("must be greater than or equal to 1")
    end

    it 'validates quantity is not a non-integer' do
      cart_item = build(:cart_item, quantity: 1.5)
      expect(cart_item.valid?).to be_falsey
      expect(cart_item.errors[:quantity]).to include("must be an integer")
    end

    it 'validates uniqueness of product_id scoped to cart_id' do
      existing = create(:cart_item)
      duplicate = build(:cart_item, cart: existing.cart, product: existing.product)
      expect(duplicate.valid?).to be_falsey
      expect(duplicate.errors[:product_id]).to include("has already been taken")
    end

    it 'allows the same product in different carts' do
      existing = create(:cart_item)
      other_cart_item = build(:cart_item, cart: create(:cart), product: existing.product)
      expect(other_cart_item.valid?).to be_truthy
    end
  end
end
