# frozen_string_literal: true

FactoryBot.define do
  factory :instrument do
    name { 'MyString' }
    base { 'MyString' }
    quote { 'MyString' }
    settlement { 'MyString' }
  end
end
