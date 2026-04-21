class AddTotalPriceDefaultToCarts < ActiveRecord::Migration[7.1]
  def change
    change_column_default :carts, :total_price, from: nil, to: 0.0
  end
end
