# frozen_string_literal: true

FactoryBot.define do
  factory :market do
    symbol { 'MyString' }
    base { 'MyString' }
    quote { 'MyString' }
  end
end
