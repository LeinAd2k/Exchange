# frozen_string_literal: true

class Position < ApplicationRecord
end

# == Schema Information
#
# Table name: positions
#
#  id                                         :bigint           not null, primary key
#  close_average_price(平仓均价)              :decimal(32, 16)  default(0.0)
#  close_volume(已平仓位)                     :bigint           default(0), not null
#  liquidation_price(强平价格)                :decimal(32, 16)  default(0.0)
#  open_average_price(开仓均价)               :decimal(32, 16)  default(0.0)
#  open_type(开仓方式 全仓cross 逐仓isolated) :string(8)        not null
#  open_volume(开仓量)                        :bigint           not null
#  side(sell or buy)                          :string(8)        not null
#  state(状态)                                :integer          default(0), not null
#  created_at                                 :datetime         not null
#  updated_at                                 :datetime         not null
#  account_id(账户)                           :bigint           not null
#  instrument_id(产品)                        :string(32)       not null
#
