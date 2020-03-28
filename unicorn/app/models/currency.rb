# frozen_string_literal: true

class Currency < ApplicationRecord
end

# == Schema Information
#
# Table name: currencies
#
#  id              :string(16)       not null, primary key
#  precision(精度) :integer          default(8), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
