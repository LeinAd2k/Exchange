# frozen_string_literal: true

module Daemons
  class Huobi < Base
    attr_accessor :ready, :cache_order_book, :counter_id, :last_update_id, :rest_order_book

    def initialize
      @ready = false
      @cache_order_book = {}
      super
    end

    def process
      url = 'wss://api.huobi.pro/ws'

      order_book_req_id = 'req_id_btcusdt_150'
      order_book_sub_id = 'sub_id_btcusdt_150'

      ws = Faye::WebSocket::Client.new(url, [], {
                                         proxy: {
                                           origin: ENV['HTTP_PROXY_URL'],
                                           headers: { 'User-Agent' => 'ruby' }
                                         }
                                       })

      ws.on :open do |_event|
        p [:open]

        sub_data = {
          sub: 'market.btcusdt.mbp.150',
          id: order_book_sub_id
        }
        ws.send(sub_data.to_json)
      end

      ws.on :message do |event|
        response = JSON.parse(ActiveSupport::Gzip.decompress(event.data.pack('c*')))

        if response['ping']
          pong_data = { pong: response['ping'] }
          ws.send(pong_data.to_json)
        elsif response['id'] == order_book_req_id
          @rest_order_book = response['data']
          @last_update_id = @rest_order_book['seqNum']
        elsif response['id'] == order_book_sub_id
          puts "#{response['subbed']} subscribed"
        elsif response['tick']
          if @ready
            if response['tick']['prevSeqNum'] != @counter_id
              puts 'prevSeqNum error'
              raise 'Missing data'
            end

            # TODO: mq
            tobe_import = []
            response['tick']['bids'].each do |bid|
              exist_ob = HuobiOrderBook.where(symbol: 'BTCUSDT', side: 'Buy', price: bid[0]).last
              if exist_ob
                exist_ob.update!(amount: bid[1])
              else
                tobe_import << {
                  symbol: 'BTCUSDT',
                  side: 'Buy',
                  price: bid[0],
                  amount: bid[1]
                }
              end
            end

            response['tick']['asks'].each do |bid|
              exist_ob = HuobiOrderBook.where(symbol: 'BTCUSDT', side: 'Sell', price: bid[0]).last
              if exist_ob
                exist_ob.update!(amount: bid[1])
              else
                tobe_import << {
                  symbol: 'BTCUSDT',
                  side: 'Sell',
                  price: bid[0],
                  amount: bid[1]
                }
              end
            end
            HuobiOrderBook.import!(tobe_import)

            HuobiOrderBook.where(symbol: 'BTCUSDT', amount: '0.00'.to_d).delete_all

            @counter_id = response['tick']['seqNum']
          else
            @cache_order_book[response['tick']['seqNum']] = response['tick']

            if @cache_order_book.size == 10
              req_data = {
                req: 'market.btcusdt.mbp.150',
                id: order_book_req_id
              }
              ws.send(req_data.to_json)
            elsif @cache_order_book.size == 20
              @cache_order_book.each do |k, _v|
                @cache_order_book.delete(k) if k <= @last_update_id
              end
              if @cache_order_book.keys.empty? || @cache_order_book.keys.first < @last_update_id
                raise 'Missing data'
              end

              puts 'Init order book'
              HuobiOrderBook.delete_all
              tobe_import = []
              @rest_order_book['bids'].each do |bid|
                tobe_import << {
                  symbol: 'BTCUSDT',
                  side: 'Buy',
                  price: bid[0],
                  amount: bid[1]
                }
              end
              @rest_order_book['asks'].each do |bid|
                tobe_import << {
                  symbol: 'BTCUSDT',
                  side: 'Sell',
                  price: bid[0],
                  amount: bid[1]
                }
              end
              HuobiOrderBook.import!(tobe_import)

              puts 'Apply order book cache'
              tobe_import = []
              @cache_order_book.each do |k, v|
                if @cache_order_book.keys.index(k) != 0 && v['prevSeqNum'] != @counter_id
                  raise 'Missing data'
                end

                v['bids'].each do |bid|
                  exist_ob = HuobiOrderBook.where(symbol: 'BTCUSDT', side: 'Buy', price: bid[0]).last
                  if exist_ob
                    exist_ob.update!(amount: bid[1])
                  else
                    tobe_import << {
                      symbol: 'BTCUSDT',
                      side: 'Buy',
                      price: bid[0],
                      amount: bid[1]
                    }
                  end
                end
                v['asks'].each do |bid|
                  exist_ob = HuobiOrderBook.where(symbol: 'BTCUSDT', side: 'Sell', price: bid[0]).last
                  if exist_ob
                    exist_ob.update!(amount: bid[1])
                  else
                    tobe_import << {
                      symbol: 'BTCUSDT',
                      side: 'Sell',
                      price: bid[0],
                      amount: bid[1]
                    }
                  end
                end

                @counter_id = k
              end
              HuobiOrderBook.import!(tobe_import)

              puts 'Order book applied'

              @cache_order_book = {}
              @ready = true
            end
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
