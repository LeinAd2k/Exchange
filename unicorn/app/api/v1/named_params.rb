# frozen_string_literal: true

module V1
  module NamedParams
    extend ::Grape::API::Helpers

    params :instrument do
      requires :symbol,
               type: String,
               desc: -> { 'Instrument symbol' },
               values: -> { Instrument.all.ids }
    end

    params :order do
      requires :side, type: String, values: -> { Order::ORDER_SIDES }
      optional :volume, type: String, desc: -> { 'Order quantity in units of the instrument' }
      optional :price, type: String, desc: -> { "Optional limit price for 'Limit', 'StopLimit', and 'LimitIfTouched' orders" }
      optional :ord_type, type: String, values: -> { Order::ORDER_TYPES }, default: 'limit', desc: -> { '' }
      #   given ord_type: ->(val) { Order::PLAN_ORDER_TYPES.include?(val) } do
      #     requires :trigger_condition, type: String, values: -> { Order::TRIGGER_CONDITIONS }, desc: -> { '' }
      #   end
      #   given ord_type: ->(val) { val == 'stop_limit' } do
      #     requires :stop_price, type: String, desc: -> { '' }
      #   end
    end
  end
end
