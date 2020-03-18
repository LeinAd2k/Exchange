# frozen_string_literal: true

class CreateHuobiOrderBooks < ActiveRecord::Migration[6.0]
  def change
    create_table :huobi_order_books do |t|
      t.string :symbol
      t.string :side # Sell or Buy
      t.decimal :amount, precision: 32, scale: 16, null: false
      t.decimal :price, precision: 32, scale: 16, null: false
    end

    add_index :huobi_order_books, %i[symbol side price]
    add_index :huobi_order_books, %i[symbol amount]
  end
end
