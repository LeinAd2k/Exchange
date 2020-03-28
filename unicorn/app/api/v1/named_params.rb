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
      optional :volume, type: BigDecimal, values: { value: ->(v) { v.try(:positive?) } }
      optional :price, type: BigDecimal, values: { value: ->(p) { p.try(:positive?) } }
      optional :ord_type, type: String, values: -> { Order::ORDER_TYPES }, default: 'limit'
      #   given ord_type: ->(val) { Order::PLAN_ORDER_TYPES.include?(val) } do
      #     requires :trigger_condition, type: String, values: -> { Order::TRIGGER_CONDITIONS }, desc: -> { '' }
      #   end
      #   given ord_type: ->(val) { val == 'stop_limit' } do
      #     requires :stop_price, type: String, desc: -> { '' }
      #   end
    end

    params :order_id do
      requires :id,
               type: String,
               allow_blank: false
    end
  end
end
