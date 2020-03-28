# frozen_string_literal: true

module V1
  class Orders < Grape::API
    helpers ::V1::NamedParams
    helpers ::V1::Helpers::OrderHelpers

    before do
      authenticate!
    end

    desc 'Get user open orders'
    params do
    end
    get '/open-orders' do
      present []
    end

    desc 'Create a new order'
    params do
      use :instrument, :order
    end
    post '/orders' do
      order = create_order(params)
      present order, with: ::V1::Entities::OrderEntity
    end

    desc 'Cancel order(s)'
    params do
      use :order_id
    end
    delete '/orders/:id/cancel' do
      order = current_user.orders.find(params[:id])
      cancel_order(order)
      present order, with: ::V1::Entities::OrderEntity
    end

    desc 'Cancel all my orders'
    delete '/orders/all' do
      orders = current_user.orders.with_state(:wait)
      orders.each { |o| cancel_order(o) }
      present orders, with: ::V1::Entities::OrderEntity
    end
  end
end
