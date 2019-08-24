# frozen_string_literal: true

class OrderBook < ApplicationRecord
  enum status: %i[wait pending cancelling canceled done]

  belongs_to :user
  belongs_to :fund
end
