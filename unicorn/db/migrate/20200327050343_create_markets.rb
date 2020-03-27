# frozen_string_literal: true

class CreateMarkets < ActiveRecord::Migration[6.0]
  def change
    create_table :markets, id: :string, limit: 32 do |t|
      t.string :name, limit: 64, null: false, comment: '名称'
      t.string :base, limit: 16, null: false, comment: '币种 eg BTC'
      t.string :quote, limit: 16, null: false, comment: '币种 eg USD'

      t.timestamps
    end
  end
end
