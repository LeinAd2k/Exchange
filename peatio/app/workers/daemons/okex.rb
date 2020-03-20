# frozen_string_literal: true

# https://www.okex.com/docs/zh/#spot_ws-full_depth
module Daemons
  class Okex < Base
    def process
      url = 'wss://real.OKEx.com:8443/ws/v3'
      symbol_name = 'okex_BTCUSDT'

      ws = Faye::WebSocket::Client.new(url, [])

      order_book_db = OrderBookClient.new

      ws.on :open do |_event|
        p [:open]
        order_book_db.drop(symbol_name)
        order_book_db.create(symbol_name)

        sub_data = { op: 'subscribe', args: ['spot/depth_l2_tbt:BTC-USDT'] }
        ws.send(sub_data.to_json)
      end

      ws.on :message do |event|
        zi = Zlib::Inflate.new(-Zlib::MAX_WBITS)
        response = JSON.parse(zi.inflate(event.data.pack('c*')))

        if response['event'] == 'subscribe'
          puts "#{response['channel']} subscribed"
        elsif response['table'] == 'spot/depth_l2_tbt'
          case response['action']
          when 'partial'
            asks_data = []
            bids_data = []
            response['data'][0]['asks'].each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              asks_data << [price, amount]
            end
            response['data'][0]['bids'].each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              bids_data << [price, amount]
            end
            order_book_db.update(symbol_name, bids_data, asks_data)
          when 'update'
            asks_data = []
            bids_data = []
            response['data'][0]['asks'].each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              asks_data << [price, amount]
            end
            response['data'][0]['bids'].each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              bids_data << [price, amount]
            end
            order_book_db.update(symbol_name, bids_data, asks_data)
          end
        else
          ap response
        end
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
    end
  end
end
