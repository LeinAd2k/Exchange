# frozen_string_literal: true

# https://docs.kraken.com/websockets/#message-book
# https://support.kraken.com/hc/en-us/articles/360027678792-Example-order-book-transcript
module Daemons
  class Kraken < Base
    def process
      url = 'wss://ws.kraken.com'

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
          pair: [
            'XBT/USD'
          ],
          subscription: {
            name: 'book',
            depth: 1000
          }
        }
        ws.send(sub_data.to_json)
      end

      ws.on :message do |event|
        response = JSON.parse(event.data)
        if response.is_a?(Hash)
          case response['event']
          when 'systemStatus'
            puts "Kraken #{response['version']} is #{response['status']}"
          when 'subscriptionStatus'
            puts "#{response['pair']} subscribed"
          end
        elsif response.is_a?(Array)
          if response[1]['as'].present? && response[1]['bs'].present?
            KrakenOrderBook.delete_all
            tobe_import = []
            response[1]['as'].each do |ob|
              tobe_import << {
                symbol: 'XBTUSD',
                side: 'Sell',
                price: ob[0],
                amount: ob[1]
              }
            end
            response[1]['bs'].each do |ob|
              tobe_import << {
                symbol: 'XBTUSD',
                side: 'Buy',
                price: ob[0],
                amount: ob[1]
              }
            end
            KrakenOrderBook.import! tobe_import
          elsif response[1]['a'].present? || response[1]['b'].present?
            tobe_import = []
            response[1]['a']&.each do |ob|
              if ob[1].to_d.zero?
                KrakenOrderBook.where(symbol: 'XBTUSD', side: 'Sell', price: ob[0]).delete_all
              elsif ob.size == 4 && ob[3] == 'r'
                tobe_import << {
                  symbol: 'XBTUSD',
                  side: 'Sell',
                  price: ob[0],
                  amount: ob[1]
                }
              else
                exist_ob = KrakenOrderBook.where(symbol: 'XBTUSD', side: 'Sell', price: ob[0]).first
                if exist_ob
                  exist_ob.update!(amount: ob[1])
                else
                  tobe_import << {
                    symbol: 'XBTUSD',
                    side: 'Sell',
                    price: ob[0],
                    amount: ob[1]
                  }
                end
              end
            end
            response[1]['b']&.each do |ob|
              if ob[1].to_d.zero?
                KrakenOrderBook.where(symbol: 'XBTUSD', side: 'Buy', price: ob[0]).delete_all
              elsif ob.size == 4 && ob[3] == 'r'
                tobe_import << {
                  symbol: 'XBTUSD',
                  side: 'Buy',
                  price: ob[0],
                  amount: ob[1]
                }
              else
                exist_ob = KrakenOrderBook.where(symbol: 'XBTUSD', side: 'Buy', price: ob[0]).first
                if exist_ob
                  exist_ob.update!(amount: ob[1])
                else
                  tobe_import << {
                    symbol: 'XBTUSD',
                    side: 'Buy',
                    price: ob[0],
                    amount: ob[1]
                  }
                end
              end
            end
            KrakenOrderBook.import! tobe_import if tobe_import.present?
            tobe_import = []
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
