require 'rails_helper'

RSpec.describe DestroyAbandonedCartJob, type: :job do
  subject(:perform) { described_class.new.perform(cart.id) }

  describe '#perform' do
    context 'when cart does not exist' do
      it 'does nothing' do
        expect { described_class.new.perform(0) }.not_to raise_error
      end
    end

    context 'when cart is abandoned and old enough' do
      let(:cart) { create(:shopping_cart, abandoned: true, last_interaction_at: (7.days + Cart::INACTIVITY_THRESHOLD).ago) }

      before do
        allow(MarkCartAsAbandonedJob).to receive(:perform_in)
        cart
      end

      it 'destroys the cart' do
        expect { perform }.to change { Cart.count }.by(-1)
      end
    end

    context 'when cart is not abandoned' do
      let(:cart) { create(:shopping_cart, last_interaction_at: (7.days + Cart::INACTIVITY_THRESHOLD).ago) }

      before do
        allow(MarkCartAsAbandonedJob).to receive(:perform_in)
        cart
      end

      it 'does not destroy the cart' do
        expect { perform }.not_to change { Cart.count }
      end
    end

    context 'when cart is abandoned but less than a week ago' do
      let(:cart) { create(:shopping_cart, abandoned: true, last_interaction_at: 3.days.ago) }

      before do
        allow(MarkCartAsAbandonedJob).to receive(:perform_in)
        cart
      end

      it 'does not destroy the cart' do
        expect { perform }.not_to change { Cart.count }
      end
    end
  end
end
