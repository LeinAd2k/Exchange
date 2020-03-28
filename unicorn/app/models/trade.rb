# frozen_string_literal: true

class Trade < ApplicationRecord
end

# == Schema Information
#
# Table name: trades
#
#  id                             :bigint           not null, primary key
#  price(价格)                    :decimal(32, 16)  default(0.0)
#  volume(量)                     :decimal(32, 16)  default(0.0)
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  ask_order_id(卖单)             :bigint           not null
#  ask_user_id(卖方)              :bigint           not null
#  bid_order_id(买单)             :bigint           not null
#  bid_user_id(买方)              :bigint           not null
#  instrument_id(商品 eg BTC_USD) :string(32)       not null
#
