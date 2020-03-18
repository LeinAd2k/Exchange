# frozen_string_literal: true

# https://www.okex.com/docs/zh/#spot_ws-full_depth
module Daemons
  class Okex < Base
    def process
      url = 'wss://real.OKEx.com:8443/ws/v3'

      ws = Faye::WebSocket::Client.new(url, [])

      ws.on :open do |_event|
        p [:open]

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
            OkexOrderBook.delete_all

            tobe_import = []
            response['data'][0]['asks'].each do |ob|
              tobe_import << {
                symbol: 'BTCUSDT',
                side: 'Sell',
                price: ob[0],
                amount: ob[1]
              }
            end
            response['data'][0]['bids'].each do |ob|
              tobe_import << {
                symbol: 'BTCUSDT',
                side: 'Buy',
                price: ob[0],
                amount: ob[1]
              }
            end
            OkexOrderBook.import! tobe_import
          when 'update'
            tobe_import = []
            response['data'][0]['asks'].each do |ob|
              exist_ob = OkexOrderBook.where(symbol: 'BTCUSDT', side: 'Sell', price: ob[0]).last
              if exist_ob
                exist_ob.update!(amount: ob[1])
              else
                tobe_import << {
                  symbol: 'BTCUSDT',
                  side: 'Sell',
                  price: ob[0],
                  amount: ob[1]
                }
              end
            end
            response['data'][0]['bids'].each do |ob|
              exist_ob = OkexOrderBook.where(symbol: 'BTCUSDT', side: 'Buy', price: ob[0]).last
              if exist_ob
                exist_ob.update!(amount: ob[1])
              else
                tobe_import << {
                  symbol: 'BTCUSDT',
                  side: 'Buy',
                  price: ob[0],
                  amount: ob[1]
                }
              end
            end
            OkexOrderBook.import! tobe_import

            OkexOrderBook.where(symbol: 'BTCUSDT', amount: '0.00'.to_d).delete_all
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
