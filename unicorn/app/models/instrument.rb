# frozen_string_literal: true

class Instrument < ApplicationRecord
end

# == Schema Information
#
# Table name: instruments
#
#  id                                      :string(32)       not null, primary key
#  base(币种 eg BTC)                       :string(16)       not null
#  name(名称)                              :string(64)       not null
#  quote(币种 eg USD)                      :string(16)       not null
#  settlement(盈亏结算和保证金币种 eg USD) :string(16)       not null
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#
