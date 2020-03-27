# frozen_string_literal: true

FactoryBot.define do
  factory :account do
    user_id { 1 }
    currency_id { 1 }
    balance { 'MyString' }
    locked { 'MyString' }
  end
end
