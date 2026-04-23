class DestroyAbandonedCartJob
  include Sidekiq::Job

  def perform(cart_id)
    cart = Cart.find_by(id: cart_id)
    return unless cart

    cart.remove_if_abandoned
  end
end
