# frozen_string_literal: true

# https://docs.pro.coinbase.com/#the-level2-channel
module Daemons
  class Coinbase < Base
    def process
      url = 'wss://ws-feed.pro.coinbase.com'
      symbol_name = 'coinbase_BTCUSD'

      ws = Faye::WebSocket::Client.new(url, [], {
                                         proxy: {
                                           origin: ENV['HTTP_PROXY_URL'],
                                           headers: { 'User-Agent' => 'ruby' }
                                         }
                                       })

      order_book_db = OrderBookClient.new

      ws.on :open do |_event|
        p [:open]
        order_book_db.drop(symbol_name)
        order_book_db.create(symbol_name)

        sub_data = {
          type: 'subscribe',
          channels: [{ "name": 'level2', "product_ids": ['BTC-USD'] }]
        }
        ws.send(sub_data.to_json)
      end

      ws.on :message do |event|
        response = JSON.parse(event.data)

        case response['type']
        when 'subscriptions'
          puts "#{response['channels'][0]['name']} subscribed"
        when 'snapshot'
          asks_data = []
          bids_data = []
          response['bids'].each do |ob|
            price = ob[0].to_d
            amount = ob[1].to_d
            bids_data << [price, amount]
          end

          response['asks'].each do |ob|
            price = ob[0].to_d
            amount = ob[1].to_d
            asks_data << [price, amount]
          end
          order_book_db.update(symbol_name, bids_data, asks_data)
        when 'l2update'
          asks_data = []
          bids_data = []
          response['changes'].each do |ob|
            price = ob[1].to_d
            amount = ob[2].to_d
            case ob[0]
            when 'buy'
              bids_data << [price, amount]
            when 'sell'
              asks_data << [price, amount]
            end
          end
          order_book_db.update(symbol_name, bids_data, asks_data)
        end
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
    end
  end
end
