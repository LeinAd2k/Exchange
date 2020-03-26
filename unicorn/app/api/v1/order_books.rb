# frozen_string_literal: true

module V1
  class OrderBooks < Grape::API
    desc 'Get current order book'
    params do
      requires :symbol, allow_blank: false, type: String, desc: 'Market symbol name'
    end
    get '/order-book' do
    end
  end
end
