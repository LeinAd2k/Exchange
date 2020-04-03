# frozen_string_literal: true

# https://binance-docs.github.io/apidocs/spot/cn/#1654ad2dd2
module Daemons
  class Binance < Base
    attr_accessor :ready, :cache_order_book, :counter_id, :last_update_id, :rest_order_book

    def initialize
      @ready = false
      @cache_order_book = {}
      super
    end

    def process
      url = 'wss://stream.binance.com:9443/ws/btcusdt@depth@100ms'
      symbol_name = 'binance_BTCUSDT'

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

        if @ready
          if response['U'] != @counter_id
            raise 'Missing data response[U] != @counter_id'
          end

          asks_data = []
          bids_data = []
          response['b'].each do |ob|
            price = ob[0].to_d
            amount = ob[1].to_d
            bids_data << [price, amount]
          end
          response['a'].each do |ob|
            price = ob[0].to_d
            amount = ob[1].to_d
            asks_data << [price, amount]
          end
          order_book_db.update(symbol_name, bids_data, asks_data)

          @counter_id = response['u'] + 1
        else
          @cache_order_book[response['u']] = response
          if @cache_order_book.size == 10
            @rest_order_book = fetch_order_book
            @last_update_id = @rest_order_book['lastUpdateId']
          elsif @cache_order_book.size == 100
            @cache_order_book.each do |k, _v|
              @cache_order_book.delete(k) if k <= @last_update_id
            end
            if @cache_order_book.keys.empty? || @cache_order_book.keys.first < @last_update_id
              raise "Missing data #{@cache_order_book.keys.empty?} || #{@cache_order_book.keys.first < @last_update_id}"
            end

            puts 'Init order book'
            asks_data = []
            bids_data = []
            @rest_order_book['bids'].each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              bids_data << [price, amount]
            end
            @rest_order_book['asks'].each do |ob|
              price = ob[0].to_d
              amount = ob[1].to_d
              asks_data << [price, amount]
            end
            order_book_db.update(symbol_name, bids_data, asks_data)

            puts 'Apply order book cache'
            @counter_id = @last_update_id + 1
            asks_data = []
            bids_data = []
            @cache_order_book.each do |k, v|
              if v['U'] != @counter_id && @cache_order_book.keys.index(k) != 0
                raise 'Missing data @cache_order_book.keys.index(k) != 0'
              end

              v['b'].each do |ob|
                price = ob[0].to_d
                amount = ob[1].to_d
                bids_data << [price, amount]
              end
              v['a'].each do |ob|
                price = ob[0].to_d
                amount = ob[1].to_d
                asks_data << [price, amount]
              end

              @counter_id = k + 1
            end
            order_book_db.update(symbol_name, bids_data, asks_data)

            puts 'Order book applied'

            @cache_order_book = {}
            @ready = true
          end
        end
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
    end

    def fetch_order_book
      order_book_path = '/api/v3/depth'
      ob_resp = conn.get(order_book_path) do |req|
        req.params = { symbol: 'BTCUSDT', limit: 5000 }
      end
      ob_resp.body
    end

    def conn
      binance_url = 'https://www.binance.com'
      @conn ||= begin
        Faraday.ignore_env_proxy = true
        Faraday.new(binance_url, proxy: ENV['HTTP_PROXY_URL']) do |f|
          f.request :url_encoded
          f .response :json, content_type: /\bjson$/

          # Last middleware must be the adapter:
          f.adapter Faraday.default_adapter
        end
      end
    end
  end
end
