# frozen_string_literal: true

# https://www.bitmex.com/app/wsAPI
module Daemons
  class Bitmex < Base
    attr_accessor :price_ids

    ZERO_D = '0.00'.to_d

    def initialize
      init
    end

    def init
      @price_ids = {}
    end

    def process
      url = 'wss://www.bitmex.com/realtime'
      symbol_name = 'bitmex_XBTUSD'

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
      end

      ws.on :message do |event|
        response = JSON.parse(event.data)
        if response['info']
          p response['info']
          to_data = {
            op: 'subscribe',
            args: ['orderBookL2:XBTUSD', 'trade:XBTUSD']
          }
          ws.send(to_data.to_json)
        elsif response['success']
          p "#{response['subscribe']} subscribed"
        else
          if response['table'] == 'orderBookL2'
            case response['action']
            when 'partial'
              asks_data = []
              bids_data = []
              response['data'].each do |ob|
                @price_ids[ob['id']] = ob['price']
                price = ob['price'].to_d
                amount = ob['size'].to_d
                case ob['side']
                when 'Sell'
                  asks_data << [price, amount]
                when 'Buy'
                  bids_data << [price, amount]
                end
              end
              order_book_db.update(symbol_name, bids_data, asks_data)
            when 'insert'
              asks_data = []
              bids_data = []
              response['data'].each do |ob|
                @price_ids[ob['id']] = ob['price']
                price = ob['price'].to_d
                amount = ob['size'].to_d
                case ob['side']
                when 'Sell'
                  asks_data << [price, amount]
                when 'Buy'
                  bids_data << [price, amount]
                end
              end
              order_book_db.update(symbol_name, bids_data, asks_data)
            when 'update'
              asks_data = []
              bids_data = []
              response['data'].each do |ob|
                price = @price_ids[ob['id']].to_d
                amount = ob['size'].to_d
                case ob['side']
                when 'Sell'
                  asks_data << [price, amount]
                when 'Buy'
                  bids_data << [price, amount]
                end
              end
              order_book_db.update(symbol_name, bids_data, asks_data)
            when 'delete'
              asks_data = []
              bids_data = []
              response['data'].each do |ob|
                price = @price_ids[ob['id']].to_d
                case ob['side']
                when 'Sell'
                  asks_data << [price, ZERO_D]
                when 'Buy'
                  bids_data << [price, ZERO_D]
                end
              end
              order_book_db.update(symbol_name, bids_data, asks_data)
            else
              logger.error "Unsupport action #{response['action']}"
            end
          elsif response['table'] == 'trade'
            case response['action']
            when 'partial'
              trades = response['data'].map do |ob|
                {
                  timestamp: DateTime.parse(ob['timestamp']).to_i,
                  side: ob['side'],
                  size: ob['size'],
                  price: ob['price']
                }
              end
              order_book_db.update_trades(symbol_name, trades)
            when 'insert'
              trades = response['data'].each do |ob|
                {
                  timestamp: DateTime.parse(ob['timestamp']).to_i,
                  side: ob['side'],
                  size: ob['size'],
                  price: ob['price']
                }
              end
              order_book_db.update_trades(symbol_name, trades)
            else
              puts "Unknown action #{response['action']}"
            end
          end
        end
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil

        order_book_db.conn.close(1000, 'Close for clean')
        init
        process
      end
    end
  end
end
