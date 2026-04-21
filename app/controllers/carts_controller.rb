class CartsController < ApplicationController
  before_action :set_cart, only: %i[ create ]

  def create
    if @cart.add_item(cart_params)
      render json: CartSerializer.new(@cart).as_json, status: :created
    else
      render json: @cart.errors, status: :unprocessable_entity
    end
  end

  private

    def set_cart
      @cart = Cart.find_by(id: session[:cart_id]) || Cart.create!
      session[:cart_id] = @cart.id
    end

    def cart_params
      params.permit(:product_id, :quantity)
    end
end
