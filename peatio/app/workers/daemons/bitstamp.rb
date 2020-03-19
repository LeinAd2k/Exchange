# frozen_string_literal: true

# https://www.bitstamp.net/websocket/v2/
module Daemons
  class Bitstamp < Base
    attr_accessor :ready, :cache_order_book, :rest_order_book, :last_microtimestamp

    def initialize
      @ready = false
      @cache_order_book = {}
      @rest_order_book = {}
      super
    end

    def process
      url = 'wss://ws.bitstamp.net'

      ws = Faye::WebSocket::Client.new(url, [], {
                                         proxy: {
                                           origin: ENV['HTTP_PROXY_URL'],
                                           headers: { 'User-Agent' => 'ruby' }
                                         }
                                       })

      ws.on :open do |_event|
        p [:open]

        sub_data = {
          event: 'bts:subscribe',
          data: {
            channel: 'diff_order_book_btcusd'
          }
        }
        ws.send(sub_data.to_json)
      end

      ws.on :message do |event|
        response = JSON.parse(event.data)

        case response['event']
        when 'bts:subscription_succeeded'
          puts "#{response['channel']} subscribed"
        when 'data'
          if @ready
            tobe_import = []
            response['data']['bids'].each do |ob|
              exist_ob = BitstampOrderBook.where(symbol: 'BTCUSD', side: 'Buy', price: ob[0]).last
              if exist_ob
                ob[1].to_d.zero? ? exist_ob.destroy! : exist_ob.update!(amount: ob[1])
              else
                tobe_import << {
                  symbol: 'BTCUSD',
                  side: 'Buy',
                  price: ob[0],
                  amount: ob[1]
                }
              end
            end
            response['data']['asks'].each do |ob|
              exist_ob = BitstampOrderBook.where(symbol: 'BTCUSD', side: 'Sell', price: ob[0]).last
              if exist_ob
                ob[1].to_d.zero? ? exist_ob.destroy! : exist_ob.update!(amount: ob[1])
              else
                tobe_import << {
                  symbol: 'BTCUSD',
                  side: 'Sell',
                  price: ob[0],
                  amount: ob[1]
                }
              end
            end
            BitstampOrderBook.import! tobe_import
            tobe_import = []
          else
            @cache_order_book[response['data']['microtimestamp']] = response['data']

            if @cache_order_book.size == 10
              @rest_order_book = fetch_order_book
              @last_microtimestamp = @rest_order_book['microtimestamp']
              puts "last_microtimestamp is #{@last_microtimestamp}"
            elsif @cache_order_book.size == 20
              @cache_order_book.each do |k, _v|
                @cache_order_book.delete(k) if k <= @last_microtimestamp
              end
              if @cache_order_book.keys.empty? || @cache_order_book.keys.first < @last_microtimestamp
                raise 'Missing data'
              end

              puts 'Init order book'
              BitstampOrderBook.delete_all

              tobe_import = []
              @rest_order_book['bids'].each do |ob|
                tobe_import << {
                  symbol: 'BTCUSD',
                  side: 'Buy',
                  price: ob[0],
                  amount: ob[1]
                }
              end
              @rest_order_book['asks'].each do |ob|
                tobe_import << {
                  symbol: 'BTCUSD',
                  side: 'Sell',
                  price: ob[0],
                  amount: ob[1]
                }
              end
              BitstampOrderBook.import! tobe_import

              puts 'Apply order book cache'
              tobe_import = []
              @cache_order_book.each do |_k, v|
                v['bids'].each do |ob|
                  exist_ob = BitstampOrderBook.where(symbol: 'BTCUSD', side: 'Buy', price: ob[0]).last
                  if exist_ob
                    ob[1].to_d.zero? ? exist_ob.destroy! : exist_ob.update!(amount: ob[1])
                  else
                    tobe_import << {
                      symbol: 'BTCUSD',
                      side: 'Buy',
                      price: ob[0],
                      amount: ob[1]
                    }
                  end
                end
                v['asks'].each do |ob|
                  exist_ob = BitstampOrderBook.where(symbol: 'BTCUSD', side: 'Sell', price: ob[0]).last
                  if exist_ob
                    ob[1].to_d.zero? ? exist_ob.destroy! : exist_ob.update!(amount: ob[1])
                  else
                    tobe_import << {
                      symbol: 'BTCUSD',
                      side: 'Sell',
                      price: ob[0],
                      amount: ob[1]
                    }
                  end
                end
                BitstampOrderBook.import! tobe_import
                tobe_import = []
              end

              puts 'Order book applied'

              @cache_order_book = {}
              @rest_order_book = {}
              @ready = true
            end
          end
        end
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
    end

    def fetch_order_book
      order_book_path = '/api/v2/order_book/btcusd'
      ob_resp = conn.get(order_book_path) do |req|
        req.params = { group: 1 }
      end
      ob_resp.body
    end

    def conn
      binance_url = 'https://www.bitstamp.net'
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
