# frozen_string_literal: true

class CreateCurrencies < ActiveRecord::Migration[6.0]
  def change
    create_table :currencies, id: :string, limit: 16, comment: '币种' do |t|
      t.integer :precision, limit: 1, default: 8, null: false, comment: '精度'
      t.datetime :deleted_at, comment: '删除时间'

      t.timestamps
    end
  end
end
