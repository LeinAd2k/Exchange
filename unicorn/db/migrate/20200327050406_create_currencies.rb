# frozen_string_literal: true

class CreateCurrencies < ActiveRecord::Migration[6.0]
  def change
    create_table :currencies, id: :string, limit: 16, comment: '币种' do |t|
      t.integer :precision, limit: 4, default: 8, null: false, comment: '精度'

      t.timestamps
    end
  end
end
