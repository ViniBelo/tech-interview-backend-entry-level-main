require 'rails_helper'

RSpec.describe Cart, type: :model do
  context 'when validating' do
    it 'validates numericality of total_price' do
      cart = described_class.new(total_price: -1)
      expect(cart.valid?).to be_falsey
      expect(cart.errors[:total_price]).to include("must be greater than or equal to 0")
    end
  end

  describe 'mark_as_abandoned' do
    let(:shopping_cart) { create(:shopping_cart) }

    it 'marks the shopping cart as abandoned if inactive for a certain time' do
      shopping_cart.update(last_interaction_at: 3.hours.ago)
      expect { shopping_cart.mark_as_abandoned }.to change { shopping_cart.abandoned? }.from(false).to(true)
    end
  end

  describe 'remove_if_abandoned' do
    let(:shopping_cart) { create(:shopping_cart, last_interaction_at: 7.days.ago) }

    it 'removes the shopping cart if abandoned for a certain time' do
      shopping_cart.mark_as_abandoned
      expect { shopping_cart.remove_if_abandoned }.to change { Cart.count }.by(-1)
    end

    it 'does not remove the shopping cart if not abandoned' do
      shopping_cart = create(:shopping_cart)
      expect { shopping_cart.remove_if_abandoned }.not_to change { Cart.count }
    end

    it 'does not remove the shopping cart if abandoned but less than a week ago' do
      shopping_cart = create(:shopping_cart, last_interaction_at: 3.days.ago, abandoned: true)
      expect { shopping_cart.remove_if_abandoned }.not_to change { Cart.count }
    end
  end

  describe 'add_item' do
    let(:shopping_cart) { create(:shopping_cart) }
    let(:product) { create(:product) }

    it 'adds an item to the cart' do
      shopping_cart.add_item(product_id: product.id, quantity: 2)
      expect(shopping_cart.cart_items.count).to eq(1)
    end

    it 'recalculates the total price after adding an item' do
      shopping_cart.add_item(product_id: product.id, quantity: 2)
      expect(shopping_cart.reload.total_price).to eq(product.price * 2)
    end

    it 'returns true on success' do
      result = shopping_cart.add_item(product_id: product.id, quantity: 1)
      expect(result).to be_truthy
    end

    it 'returns false when the item is invalid' do
      result = shopping_cart.add_item(product_id: product.id, quantity: 0)
      expect(result).to be_falsey
    end

    it 'adds errors to the cart when the item is invalid' do
      shopping_cart.add_item(product_id: product.id, quantity: 0)
      expect(shopping_cart.errors).not_to be_empty
    end
  end
end
