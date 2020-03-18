# frozen_string_literal: true

# https://docs.bitfinex.com/reference#ws-public-books
module Daemons
  class Bitfinex < Base
    def process
      url = 'wss://api-pub.bitfinex.com/ws/2'

      ws = Faye::WebSocket::Client.new(url, [], {
                                         proxy: {
                                           origin: ENV['HTTP_PROXY_URL'],
                                           headers: { 'User-Agent' => 'ruby' }
                                         }
                                       })

      ws.on :open do |_event|
        p [:open]

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
            BitfinexOrderBook.delete_all

            tobe_import = []
            response[1].each do |ob|
              next if ob[1].zero?

              tobe_import << {
                symbol: 'BTCUSDT',
                side: (ob[2].positive? ? 'Buy' : 'Sell'),
                price: ob[0],
                amount: ob[2].abs
              }
            end
            BitfinexOrderBook.import! tobe_import
          else
            ob = response[1]
            if ob.is_a?(Array)
              if ob[1].zero?
                BitfinexOrderBook.where(symbol: 'BTCUSDT', side: (ob[2].positive? ? 'Buy' : 'Sell'), price: ob[0]).delete_all
              else
                exist_ob = BitfinexOrderBook.where(symbol: 'BTCUSDT', side: (ob[2].positive? ? 'Buy' : 'Sell'), price: ob[0]).last
                if exist_ob
                  exist_ob.update!(amount: ob[2].abs)
                else
                  BitfinexOrderBook.create!(
                    symbol: 'BTCUSDT',
                    side: (ob[2].positive? ? 'Buy' : 'Sell'),
                    price: ob[0],
                    amount: ob[2].abs
                  )
                end
              end
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
