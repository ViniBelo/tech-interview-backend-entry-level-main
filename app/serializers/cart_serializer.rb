class CartSerializer
  def initialize(cart)
    @cart = cart
  end

  def as_json
    {
      id: @cart.id,
      products: @cart.cart_items.map { |item| CartItemSerializer.new(item).as_json },
      total_price: @cart.total_price
    }
  end
end
