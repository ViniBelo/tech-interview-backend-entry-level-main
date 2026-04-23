class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(cart_id)
    cart = Cart.find_by(id: cart_id)
    return unless cart

    if cart.idle? && !cart.abandoned?
      cart.mark_as_abandoned
      DestroyAbandonedCartJob.perform_in(cart.updated_at + Cart::ABANDONMENT_PERIOD, cart_id)
    end

    self.class.perform_in(cart.last_interaction_at + Cart::INACTIVITY_THRESHOLD, cart_id)
  end
end
