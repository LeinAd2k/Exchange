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

      ws = Faye::WebSocket::Client.new(url, [], {
                                         proxy: {
                                           origin: ENV['HTTP_PROXY_URL'],
                                           headers: { 'User-Agent' => 'ruby' }
                                         }
                                       })

      ws.on :open do |_event|
        p [:open]
      end

      ws.on :message do |event|
        response = JSON.parse(event.data)

        if @ready
          raise 'Missing data' if response['U'] != @counter_id

          response['b'].each do |ob|
            exist_ob = BinanceOrderBook.where(symbol: 'BTCUSDT', side: 'Buy', price: ob[0]).last
            if exist_ob
              exist_ob.update!(amount: ob[1])
            else
              BinanceOrderBook.create!(
                symbol: 'BTCUSDT',
                side: 'Buy',
                price: ob[0],
                amount: ob[1]
              )
            end
          end
          response['a'].each do |ob|
            exist_ob = BinanceOrderBook.where(symbol: 'BTCUSDT', side: 'Sell', price: ob[0]).last
            if exist_ob
              exist_ob.update!(amount: ob[1])
            else
              BinanceOrderBook.create!(
                symbol: 'BTCUSDT',
                side: 'Sell',
                price: ob[0],
                amount: ob[1]
              )
            end
          end

          BinanceOrderBook.where(symbol: 'BTCUSDT', amount: '0.00'.to_d).delete_all

          @counter_id = response['u'] + 1
        else
          @cache_order_book[response['u']] = response
          if @cache_order_book.size == 10
            @rest_order_book = fetch_order_book
            @last_update_id = @rest_order_book['lastUpdateId']
            ap "lastUpdateId is #{@last_update_id}"
          elsif @cache_order_book.size == 50
            @cache_order_book.each do |k, _v|
              @cache_order_book.delete(k) if k <= @last_update_id
            end
            if @cache_order_book.keys.empty? || @cache_order_book.keys.first < @last_update_id
              raise 'Missing data'
            end

            puts 'Init order book'
            BinanceOrderBook.delete_all
            @rest_order_book['bids'].each do |ob|
              BinanceOrderBook.create!(
                symbol: 'BTCUSDT',
                side: 'Buy',
                price: ob[0],
                amount: ob[1]
              )
            end
            @rest_order_book['asks'].each do |ob|
              BinanceOrderBook.create!(
                symbol: 'BTCUSDT',
                side: 'Sell',
                price: ob[0],
                amount: ob[1]
              )
            end

            puts 'Apply order book cache'
            @counter_id = @last_update_id + 1
            @cache_order_book.each do |k, v|
              if v['U'] != @counter_id && @cache_order_book.keys.index(k) != 0
                raise 'Missing data'
              end

              v['b'].each do |ob|
                exist_ob = BinanceOrderBook.where(symbol: 'BTCUSDT', side: 'Buy', price: ob[0]).last
                if exist_ob
                  exist_ob.update!(amount: ob[1])
                else
                  BinanceOrderBook.create!(
                    symbol: 'BTCUSDT',
                    side: 'Buy',
                    price: ob[0],
                    amount: ob[1]
                  )
                end
              end
              v['a'].each do |ob|
                exist_ob = BinanceOrderBook.where(symbol: 'BTCUSDT', side: 'Sell', price: ob[0]).last
                if exist_ob
                  exist_ob.update!(amount: ob[1])
                else
                  BinanceOrderBook.create!(
                    symbol: 'BTCUSDT',
                    side: 'Sell',
                    price: ob[0],
                    amount: ob[1]
                  )
                end
              end

              @counter_id = k + 1
            end

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
        req.params = { symbol: 'BTCUSDT', limit: 1000 }
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
