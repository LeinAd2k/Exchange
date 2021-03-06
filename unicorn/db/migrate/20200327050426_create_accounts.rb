# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts, comment: '币种账户' do |t|
      t.bigint :user_id, null: false, comment: '用户'
      t.string :currency_id, limit: 16, null: false, comment: '币种'
      t.decimal :balance, default: 0, precision: 32, scale: 16, comment: '余额'
      t.decimal :locked, default: 0, precision: 32, scale: 16, comment: '锁定金额'

      t.timestamps
    end
  end
end
