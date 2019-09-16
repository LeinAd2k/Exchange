# frozen_string_literal: true

class CreateTrades < ActiveRecord::Migration[6.0]
  def change
    create_table :trades, comment: '交易记录' do |t|
      t.bigint :ask_user_id, null: false, comment: '卖方'
      t.bigint :bid_user_id, null: false, comment: '买方'
      t.bigint :ask_order_id, null: false, comment: '卖单'
      t.bigint :bid_order_id, null: false, comment: '买单'
      t.string :symbol, null: false, comment: '简称 eg BTC_USD'
      t.bigint :fund_id, null: false, comment: '商品'
      t.decimal :volume, default: 0, precision: 32, scale: 16, comment: '量'
      t.decimal :price, default: 0, precision: 32, scale: 16, comment: '价格'
      t.decimal :taker_fee, default: 0, precision: 32, scale: 16, comment: 'taker手续费'
      t.decimal :maker_fee, default: 0, precision: 32, scale: 16, comment: 'maker手续费'
      t.datetime :deleted_at, comment: '删除时间'

      t.timestamps
    end
  end
end
