class DestroyAbandonedCartJob
  include Sidekiq::Job

  def perform(cart_id)
    cart = Cart.find_by(id: cart_id)
    return unless cart

    unless cart.remove_if_abandoned
      MarkCartAsAbandonedJob.perform_in(cart.last_interaction_at + Cart::INACTIVITY_THRESHOLD, cart_id)
    end
  end
end
