# frozen_string_literal: true

class CreateFunds < ActiveRecord::Migration[6.0]
  def change
    create_table :funds, id: :string, limit: 32, comment: '商品' do |t|
      t.string :name, null: false, comment: '名称'
      t.string :base, limit: 16, null: false, comment: '币种 eg BTC'
      t.string :quote, limit: 16, null: false, comment: '币种 eg USD'
      t.datetime :deleted_at, comment: '删除时间'

      t.timestamps
    end

    add_index :funds, :base
    add_index :funds, :quote
  end
end
