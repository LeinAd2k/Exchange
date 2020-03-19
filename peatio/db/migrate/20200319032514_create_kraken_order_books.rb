# frozen_string_literal: true

class CreateKrakenOrderBooks < ActiveRecord::Migration[6.0]
  def change
    create_table :kraken_order_books do |t|
      t.string :symbol
      t.string :side # Sell or Buy
      t.decimal :amount, precision: 32, scale: 16, null: false
      t.decimal :price, precision: 32, scale: 16, null: false
    end

    add_index :kraken_order_books, %i[symbol side price]
  end
end
