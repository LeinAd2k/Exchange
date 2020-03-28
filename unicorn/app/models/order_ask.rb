# frozen_string_literal: true

class OrderAsk < Order
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
