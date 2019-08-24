# frozen_string_literal: true

class Account < ApplicationRecord
  belongs_to :user
  belongs_to :currency

  has_many :deposits
  has_many :withdraws
end
