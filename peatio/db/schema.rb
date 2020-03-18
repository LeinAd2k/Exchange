# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_03_18_143416) do

  create_table "binance_order_books", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "symbol"
    t.string "side"
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.decimal "price", precision: 32, scale: 16, null: false
    t.index ["symbol", "amount"], name: "index_binance_order_books_on_symbol_and_amount"
    t.index ["symbol", "side", "price"], name: "index_binance_order_books_on_symbol_and_side_and_price"
  end

  create_table "bitfinex_order_books", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "symbol"
    t.string "side"
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.decimal "price", precision: 32, scale: 16, null: false
    t.index ["symbol", "side", "price"], name: "index_bitfinex_order_books_on_symbol_and_side_and_price"
  end

  create_table "bitmex_order_books", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "symbol"
    t.string "side"
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.decimal "price", precision: 32, scale: 16, null: false
    t.index ["symbol", "side"], name: "index_bitmex_order_books_on_symbol_and_side"
  end

  create_table "huobi_order_books", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "symbol"
    t.string "side"
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.decimal "price", precision: 32, scale: 16, null: false
    t.index ["symbol", "amount"], name: "index_huobi_order_books_on_symbol_and_amount"
    t.index ["symbol", "side", "price"], name: "index_huobi_order_books_on_symbol_and_side_and_price"
  end

  create_table "okex_order_books", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", force: :cascade do |t|
    t.string "symbol"
    t.string "side"
    t.decimal "amount", precision: 32, scale: 16, null: false
    t.decimal "price", precision: 32, scale: 16, null: false
    t.index ["symbol", "amount"], name: "index_okex_order_books_on_symbol_and_amount"
    t.index ["symbol", "side", "price"], name: "index_okex_order_books_on_symbol_and_side_and_price"
  end

end
