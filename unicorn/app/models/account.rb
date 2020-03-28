# frozen_string_literal: true

class Account < ApplicationRecord
end

# == Schema Information
#
# Table name: accounts
#
#  id                :bigint           not null, primary key
#  balance(余额)     :decimal(32, 16)  default(0.0)
#  locked(锁定金额)  :decimal(32, 16)  default(0.0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  currency_id(币种) :string(16)       not null
#  user_id(用户)     :bigint           not null
#
