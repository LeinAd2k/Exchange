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

ActiveRecord::Schema.define(version: 2019_10_25_053838) do

  create_table "accounts", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "币种账户", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "用户"
    t.string "currency_id", limit: 16, null: false, comment: "币种"
    t.decimal "balance", precision: 32, scale: 16, default: "0.0", comment: "余额"
    t.decimal "locked", precision: 32, scale: 16, default: "0.0", comment: "锁定金额"
    t.datetime "deleted_at", comment: "删除时间"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["currency_id"], name: "index_accounts_on_currency_id"
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "currencies", id: :string, limit: 16, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "币种", force: :cascade do |t|
    t.integer "precision", default: 8, null: false, comment: "精度"
    t.datetime "deleted_at", comment: "删除时间"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "deposits", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "存款记录", force: :cascade do |t|
    t.bigint "account_id", null: false, comment: "账户"
    t.string "currency_id", limit: 16, null: false, comment: "币种"
    t.decimal "amount", precision: 32, scale: 16, default: "0.0", comment: "金额"
    t.decimal "fee", precision: 32, scale: 16, default: "0.0", comment: "手续费"
    t.datetime "deleted_at", comment: "删除时间"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_deposits_on_account_id"
    t.index ["currency_id"], name: "index_deposits_on_currency_id"
  end

  create_table "funds", id: :string, limit: 32, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "商品", force: :cascade do |t|
    t.string "name", limit: 64, null: false, comment: "名称"
    t.string "base", limit: 16, null: false, comment: "币种 eg BTC"
    t.string "quote", limit: 16, null: false, comment: "币种 eg USD"
    t.datetime "deleted_at", comment: "删除时间"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["base"], name: "index_funds_on_base"
    t.index ["quote"], name: "index_funds_on_quote"
  end

  create_table "orders", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "订单", force: :cascade do |t|
    t.bigint "user_id", null: false, comment: "买方/卖方"
    t.string "fund_id", null: false, comment: "商品"
    t.integer "state", limit: 1, default: 0, null: false, comment: "状态"
    t.string "order_type", limit: 16, null: false, comment: "订单类型 市价单market 限价单limit"
    t.string "side", limit: 8, null: false, comment: "sell or buy"
    t.decimal "volume", precision: 32, scale: 16, default: "0.0", comment: "量"
    t.decimal "origin_volume", precision: 32, scale: 16, default: "0.0", comment: "原始量"
    t.decimal "price", precision: 32, scale: 16, default: "0.0", comment: "价格"
    t.decimal "taker_fee", precision: 32, scale: 16, default: "0.0", comment: "taker手续费"
    t.decimal "maker_fee", precision: 32, scale: 16, default: "0.0", comment: "maker手续费"
    t.datetime "deleted_at", comment: "删除时间"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["fund_id"], name: "index_orders_on_fund_id"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "positions", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "仓位", force: :cascade do |t|
    t.string "fund_id", limit: 32, null: false, comment: "产品"
    t.bigint "account_id", null: false, comment: "账户"
    t.decimal "open_average_price", precision: 32, scale: 16, default: "0.0", comment: "开仓均价"
    t.decimal "close_average_price", precision: 32, scale: 16, default: "0.0", comment: "平仓均价"
    t.decimal "liquidation_price", precision: 32, scale: 16, default: "0.0", comment: "强平价格"
    t.string "open_type", limit: 8, null: false, comment: "开仓方式 全仓cross 逐仓isolated"
    t.string "side", limit: 8, null: false, comment: "sell or buy"
    t.integer "state", limit: 1, default: 0, null: false, comment: "状态"
    t.bigint "open_volume", null: false, comment: "开仓量"
    t.bigint "close_volume", default: 0, null: false, comment: "已平仓位"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "trades", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "交易记录", force: :cascade do |t|
    t.bigint "ask_user_id", null: false, comment: "卖方"
    t.bigint "bid_user_id", null: false, comment: "买方"
    t.bigint "ask_order_id", null: false, comment: "卖单"
    t.bigint "bid_order_id", null: false, comment: "买单"
    t.string "fund_id", limit: 32, null: false, comment: "商品 eg BTC_USD"
    t.decimal "volume", precision: 32, scale: 16, default: "0.0", comment: "量"
    t.decimal "price", precision: 32, scale: 16, default: "0.0", comment: "价格"
    t.decimal "taker_fee", precision: 32, scale: 16, default: "0.0", comment: "taker手续费"
    t.decimal "maker_fee", precision: 32, scale: 16, default: "0.0", comment: "maker手续费"
    t.datetime "deleted_at", comment: "删除时间"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "用户", force: :cascade do |t|
    t.string "name", limit: 64, null: false, comment: "用户名"
    t.string "password_digest", null: false, comment: "密码"
    t.string "email", limit: 128, null: false, comment: "有限"
    t.string "role", limit: 16, comment: "角色"
    t.string "address", comment: "地址"
    t.datetime "deleted_at", comment: "删除时间"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "withdraws", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4", comment: "提现记录", force: :cascade do |t|
    t.bigint "account_id", null: false, comment: "账户"
    t.string "currency_id", limit: 16, null: false, comment: "币种"
    t.decimal "amount", precision: 32, scale: 16, default: "0.0", comment: "金额"
    t.decimal "fee", precision: 32, scale: 16, default: "0.0", comment: "手续费"
    t.datetime "deleted_at", comment: "删除时间"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_withdraws_on_account_id"
    t.index ["currency_id"], name: "index_withdraws_on_currency_id"
  end

end
