class CartsController < ApplicationController
  before_action :set_or_create_cart, only: %i[create]
  before_action :set_cart, only: %i[show add_item remove_item]

  def create
    if @cart.add_item(cart_params)
      render json: CartSerializer.new(@cart).as_json, status: :created
    else
      render json: @cart.errors, status: :unprocessable_entity
    end
  end

  def add_item
    if @cart.change_item_quantity(cart_params)
      render json: CartSerializer.new(@cart).as_json
    else
      render json: @cart.errors, status: :unprocessable_entity
    end
  end

  def show
    render json: CartSerializer.new(@cart).as_json
  end

  def remove_item
    if @cart.remove_item(item_to_remove)
      render json: CartSerializer.new(@cart).as_json
    else
      render json: @cart.errors, status: :unprocessable_entity
    end
  end

  private

    def set_or_create_cart
      @cart = find_cart || Cart.create!
      session[:cart_id] = @cart.id
    end

    def set_cart
      @cart = find_cart
      render json: { error: 'Cart not found' }, status: :not_found unless @cart
    end

    def find_cart
      Cart.find_by(id: session[:cart_id])
    end

    def cart_params
      params.permit(:product_id, :quantity)
    end

    def item_to_remove
      params.permit(:product_id)[:product_id]
    end
end
