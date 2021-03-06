# frozen_string_literal: true

class Order < ApplicationRecord
  ORDER_SIDES = %w[sell buy].freeze
  ORDER_TYPES = %w[market limit stop_market stop_limit market_if_touched limit_if_touched].freeze
  PLAN_ORDER_TYPES = %w[stop_limit stop_market].freeze

  belongs_to :user

  PENDING = 'pending'
  WAIT    = 'wait'
  DONE    = 'done'
  CANCEL  = 'cancel'
  REJECT  = 'reject'

  scope :done, -> { with_state(:done) }
  scope :active, -> { with_state(:wait) }
end

# == Schema Information
#
# Table name: orders
#
#  id                                            :bigint           not null, primary key
#  order_type(订单类型 市价单market 限价单limit) :string(16)       not null
#  origin_volume(原始量)                         :decimal(32, 16)  default(0.0)
#  price(价格)                                   :decimal(32, 16)  default(0.0)
#  side(sell or buy)                             :string(8)        not null
#  state(状态)                                   :integer          default(0), not null
#  volume(量)                                    :decimal(32, 16)  default(0.0)
#  created_at                                    :datetime         not null
#  updated_at                                    :datetime         not null
#  instrument_id(商品)                           :string(255)      not null
#  user_id(买方/卖方)                            :bigint           not null
#
