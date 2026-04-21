class CreateCartItems < ActiveRecord::Migration[7.1]
  def change
    create_table :cart_items, id: false do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, default: 0
      t.decimal :total_price, precision: 17, scale: 2, default: 0.0

      t.timestamps
    end

    add_index :cart_items, [ :cart_id, :product_id ], unique: true
  end
end
