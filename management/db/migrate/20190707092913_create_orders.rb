# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders, comment: '订单' do |t|
      t.bigint :user_id, null: false, comment: '买方/卖方'
      t.string :fund_id, null: false, comment: '商品'
      t.integer :state, null: false, default: 0, limit: 1, comment: '状态'
      t.string :order_type, limit: 16, null: false, comment: '订单类型 市价单market 限价单limit'
      t.string :side, limit: 8, null: false, comment: 'sell or buy'
      t.decimal :volume, default: 0, precision: 32, scale: 16, comment: '量'
      t.decimal :origin_volume, default: 0, precision: 32, scale: 16, comment: '原始量'
      t.decimal :price, default: 0, precision: 32, scale: 16, comment: '价格'
      t.decimal :taker_fee, default: 0, precision: 32, scale: 16, comment: 'taker手续费'
      t.decimal :maker_fee, default: 0, precision: 32, scale: 16, comment: 'maker手续费'
      t.datetime :deleted_at, comment: '删除时间'

      t.timestamps
    end

    add_index :orders, :user_id
    add_index :orders, :fund_id
  end
end
