require 'rails_helper'

RSpec.describe "/carts", type: :request do
  describe "POST /cart" do
    let(:product) { create(:product) }
    context 'when the product is not in the cart' do
      subject(:add_to_cart) do
        post '/cart', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'creates a new cart item' do
        expect { add_to_cart }.to change(CartItem, :count).by(1)
      end

      it 'associates the item with the correct product' do
        add_to_cart
        cart = Cart.find(session[:cart_id])
        expect(cart.cart_items.last.product).to eq(product)
      end

      it 'returns a successful response' do
        add_to_cart
        expect(response).to have_http_status(:created)
      end

      it 'returns the cart in the response body' do
        add_to_cart
        json = JSON.parse(response.body)
        expect(json).to include('id', 'products')
      end
    end

    context 'with invalid product_id' do
      it 'returns a not found response' do
        post '/cart', params: { product_id: 0, quantity: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid quantity' do
      it 'rejects zero quantity' do
        post '/cart', params: { product_id: product.id, quantity: 0 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'rejects negative quantity' do
        post '/cart', params: { product_id: product.id, quantity: -1 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /cart" do
    context 'when no cart exists in the session' do
      it 'returns not found' do
        get '/cart', as: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'does not create a cart' do
        expect { get '/cart', as: :json }.not_to change(Cart, :count)
      end
    end

    context 'when a cart exists in the session' do
      let(:product) { create(:product) }

      before { post '/cart', params: { product_id: product.id, quantity: 2 }, as: :json }

      it 'returns ok' do
        get '/cart', as: :json
        expect(response).to have_http_status(:ok)
      end

      it 'returns the cart id' do
        get '/cart', as: :json
        expect(JSON.parse(response.body)).to have_key('id')
      end

      it 'returns the cart items' do
        get '/cart', as: :json
        expect(JSON.parse(response.body)['products'].length).to eq(1)
      end

      it 'returns the correct total_price' do
        get '/cart', as: :json
        expect(JSON.parse(response.body)['total_price'].to_f).to eq(product.price * 2)
      end
    end
  end

  describe "POST /add_items" do
    let(:cart) { Cart.create }
    let(:product) { Product.create(name: "Test Product", price: 10.0) }
    let!(:cart_item) { CartItem.create(cart: cart, product: product, quantity: 1) }

    context 'when the product already is in the cart' do
      subject do
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
        post '/cart/add_items', params: { product_id: product.id, quantity: 1 }, as: :json
      end

      it 'updates the quantity of the existing item in the cart' do
        expect { subject }.to change { cart_item.reload.quantity }.by(2)
      end
    end
  end
end
