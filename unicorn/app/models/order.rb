# frozen_string_literal: true

class Order < ApplicationRecord
  ORDER_SIDES = %w[sell buy].freeze
  ORDER_TYPES = %w[market limit stop_market stop_limit market_if_touched limit_if_touched].freeze
  PLAN_ORDER_TYPES = %w[stop_limit stop_market].freeze
end
