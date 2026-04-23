require 'rails_helper'

RSpec.describe MarkCartAsAbandonedJob, type: :job do
  subject(:perform) { described_class.new.perform(cart.id) }

  describe '#perform' do
    context 'when cart does not exist' do
      it 'does nothing' do
        expect { described_class.new.perform(0) }.not_to raise_error
      end

      it 'does not reschedule' do
        described_class.new.perform(0)
        expect(described_class.jobs).to be_empty
      end
    end

    context 'when cart is already abandoned' do
      let(:cart) { create(:shopping_cart, abandoned: true, last_interaction_at: 4.hours.ago) }

      before { cart; Sidekiq::Worker.clear_all }

      it 'does not change abandoned status' do
        expect { perform }.not_to change { cart.reload.abandoned }
      end

      it 'does not schedule the destroy job' do
        perform
        expect(DestroyAbandonedCartJob.jobs).to be_empty
      end

      it 'reschedules the job immediately (threshold already passed)' do
        perform
        job = described_class.jobs.first
        expect(job).not_to be_nil
        expect(job['args']).to eq([cart.id])
        expect(job['at']).to be_nil
      end
    end

    context 'when cart is idle' do
      let(:cart) { create(:shopping_cart, last_interaction_at: 4.hours.ago) }

      before { cart; Sidekiq::Worker.clear_all }

      it 'marks the cart as abandoned' do
        expect { perform }.to change { cart.reload.abandoned }.from(false).to(true)
      end

      it 'schedules the destroy job' do
        perform
        job = DestroyAbandonedCartJob.jobs.first
        expect(job).not_to be_nil
        expect(job['args']).to eq([cart.id])
        expect(Time.at(job['at'])).to be_within(1.second).of(cart.reload.updated_at + Cart::ABANDONMENT_PERIOD)
      end

      it 'reschedules the job immediately (threshold already passed)' do
        perform
        job = described_class.jobs.first
        expect(job).not_to be_nil
        expect(job['args']).to eq([cart.id])
        expect(job['at']).to be_nil
      end
    end

    context 'when cart is exactly at the threshold' do
      let(:cart) { create(:shopping_cart, last_interaction_at: Cart::INACTIVITY_THRESHOLD.ago) }

      before { cart; Sidekiq::Worker.clear_all }

      it 'marks the cart as abandoned' do
        expect { perform }.to change { cart.reload.abandoned }.from(false).to(true)
      end

      it 'reschedules the job immediately (threshold already passed)' do
        perform
        job = described_class.jobs.first
        expect(job).not_to be_nil
        expect(job['args']).to eq([cart.id])
        expect(job['at']).to be_nil
      end
    end

    context 'when cart is not yet idle' do
      let(:cart) { create(:shopping_cart, last_interaction_at: 1.hour.ago) }

      before { cart; Sidekiq::Worker.clear_all }

      it 'does not mark the cart as abandoned' do
        expect { perform }.not_to change { cart.reload.abandoned }
      end

      it 'reschedules the job' do
        perform
        job = described_class.jobs.first
        expect(job).not_to be_nil
        expect(job['args']).to eq([cart.id])
        expect(Time.at(job['at'])).to be_within(1.second).of(cart.last_interaction_at + Cart::INACTIVITY_THRESHOLD)
      end

      it 'does not schedule the destroy job' do
        perform
        expect(DestroyAbandonedCartJob.jobs).to be_empty
      end
    end
  end
end
