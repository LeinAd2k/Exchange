# frozen_string_literal: true

class Withdraw < ApplicationRecord
  belongs_to :account
  belongs_to :currency
end
