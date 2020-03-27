# frozen_string_literal: true

class CreatePositions < ActiveRecord::Migration[6.0]
  def change
    create_table :positions, comment: '仓位' do |t|
      t.string :instrument_id, limit: 32, null: false, comment: '产品'
      t.bigint :account_id, null: false, comment: '账户'
      t.decimal :open_average_price, default: 0, precision: 32, scale: 16, comment: '开仓均价'
      t.decimal :close_average_price, default: 0, precision: 32, scale: 16, comment: '平仓均价'
      t.decimal :liquidation_price, default: 0, precision: 32, scale: 16, comment: '强平价格'
      t.string :open_type, limit: 8, null: false, comment: '开仓方式 全仓cross 逐仓isolated'
      t.string :side, limit: 8, null: false, comment: 'sell or buy'
      t.integer :state, limit: 1, null: false, default: 0, comment: '状态'
      t.bigint :open_volume, null: false, comment: '开仓量'
      t.bigint :close_volume, null: false, default: 0, comment: '已平仓位'

      t.timestamps
    end
  end
end
