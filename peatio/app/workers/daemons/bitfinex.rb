# frozen_string_literal: true

# https://docs.bitfinex.com/reference#ws-public-books
module Daemons
  class Bitfinex < Base
    ZERO_D = '0.00'.to_d

    def process
      url = 'wss://api-pub.bitfinex.com/ws/2'
      symbol_name = 'bitfinex_XBTUSD'

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
          event: 'subscribe',
          channel: 'book',
          symbol: 'tBTCUSD',
          prec: 'P1', # P0, P1, P2, P3, P4
          freq: 'F0', # F0=realtime, F1=2sec
          len: 100 # 25, 100
        }
        ws.send(sub_data.to_json)
      end

      ws.on :message do |event|
        response = JSON.parse(event.data)

        if response.is_a?(Hash)
          if response['event'] == 'info'
            puts "Bitfinex version #{response['version']}"
          elsif response['event'] == 'subscribed'
            puts "#{response['symbol']} order book subscribed #{response['chanId']}"
          end
        elsif response.is_a?(Array)
          if response[1][0].is_a?(Array)
            asks_data = []
            bids_data = []
            response[1].each do |ob|
              next if ob[1].zero?

              price = ob[0].to_d
              amount = ob[2].to_d
              amount.positive? ? bids_data << [price, amount.abs] : asks_data << [price, amount.abs]
            end
            order_book_db.update(symbol_name, bids_data, asks_data)
          else
            ob = response[1]
            if ob.is_a?(Array)
              asks_data = []
              bids_data = []
              price = ob[0].to_d
              amount = ob[2].to_d

              if ob[1].zero?
                amount.positive? ? bids_data << [price, ZERO_D] : asks_data << [price, ZERO_D]
              else
                amount.positive? ? bids_data << [price, amount.abs] : asks_data << [price, amount.abs]
              end
              order_book_db.update(symbol_name, bids_data, asks_data)
            else
              ap response
            end
          end
        end
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
    end
  end
end
