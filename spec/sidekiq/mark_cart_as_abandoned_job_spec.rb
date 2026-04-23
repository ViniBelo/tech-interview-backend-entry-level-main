require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  subject(:perform) { described_class.new.perform(cart.id) }

  describe '#perform' do
    context 'when cart does not exist' do
      it 'does nothing' do
        expect { described_class.new.perform(0) }.not_to raise_error
      end

      it 'does not reschedule' do
        expect(described_class).not_to receive(:perform_in)
        described_class.new.perform(0)
      end
    end

    context 'when cart is already abandoned' do
      let(:cart) { create(:shopping_cart, abandoned: true, last_interaction_at: 4.hours.ago) }

      before do
        allow(described_class).to receive(:perform_in)
        allow(DestroyAbandonedCartJob).to receive(:perform_in)
        cart
      end

      it 'does not change abandoned status' do
        expect { perform }.not_to change { cart.reload.abandoned }
      end
    end

    context 'when cart is idle' do
      let(:cart) { create(:shopping_cart, last_interaction_at: 4.hours.ago) }

      before do
        allow(described_class).to receive(:perform_in)
        allow(DestroyAbandonedCartJob).to receive(:perform_in)
        cart
      end

      it 'marks the cart as abandoned' do
        expect { perform }.to change { cart.reload.abandoned }.from(false).to(true)
      end

      it 'does not reschedule the job' do
        expect(described_class).not_to receive(:perform_in)
        perform
      end

      it 'schedules the destroy job' do
        perform
        expect(DestroyAbandonedCartJob).to have_received(:perform_in).with(cart.reload.updated_at + Cart::ABANDONMENT_PERIOD, cart.id)
      end
    end

    context 'when cart is exactly at the threshold' do
      let(:cart) { create(:shopping_cart, last_interaction_at: Cart::INACTIVITY_THRESHOLD.ago) }

      it 'marks the cart as abandoned' do
        expect { perform }.to change { cart.reload.abandoned }.from(false).to(true)
      end
    end

    context 'when cart is not yet idle' do
      let(:cart) { create(:shopping_cart, last_interaction_at: 1.hour.ago) }

      it 'does not mark the cart as abandoned' do
        expect { perform }.not_to change { cart.reload.abandoned }
      end

      it 'reschedules the job' do
        expect(described_class).to receive(:perform_in).with(cart.last_interaction_at + Cart::INACTIVITY_THRESHOLD, cart.id)
        perform
      end

      it 'does not schedule the destroy job' do
        allow(described_class).to receive(:perform_in)
        expect(DestroyAbandonedCartJob).not_to receive(:perform_in)
        perform
      end
    end
  end
end
