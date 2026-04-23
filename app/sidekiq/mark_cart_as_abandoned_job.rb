class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(cart_id)
    cart = Cart.find_by(id: cart_id)
    return unless cart
    return if cart.abandoned?

    if cart.idle?
      cart.mark_as_abandoned
      DestroyAbandonedCartJob.perform_in(cart.updated_at + Cart::ABANDONMENT_PERIOD, cart_id)
    else
      self.class.perform_in(cart.last_interaction_at + Cart::INACTIVITY_THRESHOLD, cart_id)
    end
  end
end
