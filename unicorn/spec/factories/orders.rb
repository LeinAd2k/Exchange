# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    user_id { 1 }
    symbol { 'MyString' }
    fund_id { 1 }
    order_type { 'MyString' }
    side { 'MyString' }
    volume { 1.5 }
    price { 1.5 }
    ask_fee { 1.5 }
    bid_fee { 1.5 }
  end
end
