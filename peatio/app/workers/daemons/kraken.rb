# frozen_string_literal: true

# https://docs.kraken.com/websockets/#message-book
# https://support.kraken.com/hc/en-us/articles/360027678792-Example-order-book-transcript
module Daemons
  class Kraken < Base
    def process
      url = 'wss://ws.kraken.com'
      symbol_name = 'kraken_XBTUSD'

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
            asks_data = []
            bids_data = []
            response[1]['as'].each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              asks_data << [price, amount]
            end
            response[1]['bs'].each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              bids_data << [price, amount]
            end
            order_book_db.update(symbol_name, bids_data, asks_data)
          elsif response[1]['a'].present? || response[1]['b'].present?
            asks_data = []
            bids_data = []
            response[1]['a']&.each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              asks_data << [price, amount]
            end
            response[1]['b']&.each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              bids_data << [price, amount]
            end
            order_book_db.update(symbol_name, bids_data, asks_data)
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
