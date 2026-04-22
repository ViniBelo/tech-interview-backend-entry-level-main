class MarkCartAsAbandonedJob
  include Sidekiq::Job

  def perform(cart_id)
    cart = Cart.find_by(id: cart_id)
    return unless cart

    cart.mark_as_abandoned if cart.idle?

    self.class.perform_in(cart.last_interaction_at + Cart::INACTIVITY_THRESHOLD, cart_id)
  end
end
