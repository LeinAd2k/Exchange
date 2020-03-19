# frozen_string_literal: true

# https://docs.pro.coinbase.com/#the-level2-channel
module Daemons
  class Coinbase < Base
    def process
      url = 'wss://ws-feed.pro.coinbase.com'

      ws = Faye::WebSocket::Client.new(url, [], {
                                         proxy: {
                                           origin: ENV['HTTP_PROXY_URL'],
                                           headers: { 'User-Agent' => 'ruby' }
                                         }
                                       })

      ws.on :open do |_event|
        p [:open]

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
          CoinbaseOrderBook.delete_all

          tobe_import = []
          response['bids'].each do |ob|
            tobe_import << {
              symbol: 'BTCUSD',
              side: 'Buy',
              price: ob[0],
              amount: ob[1]
            }
          end

          response['asks'].each do |ob|
            tobe_import << {
              symbol: 'BTCUSD',
              side: 'Sell',
              price: ob[0],
              amount: ob[1]
            }
          end
          CoinbaseOrderBook.import! tobe_import
        when 'l2update'
          tobe_import = []
          response['changes'].each do |ob|
            exist_ob = CoinbaseOrderBook.where(symbol: 'BTCUSD', side: ob[0], price: ob[1]).last
            if exist_ob
              ob[2].to_d.zero? ? exist_ob.destroy! : exist_ob.update!(amount: ob[2])
            else
              tobe_import << {
                symbol: 'BTCUSD',
                side: ob[0],
                price: ob[1],
                amount: ob[2]
              }
            end
          end
          CoinbaseOrderBook.import!(tobe_import) if tobe_import.present?
        end
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
    end
  end
end
