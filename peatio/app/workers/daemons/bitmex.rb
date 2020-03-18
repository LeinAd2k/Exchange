# frozen_string_literal: true

module Daemons
  class Bitmex < Base
    def process
      url = 'wss://www.bitmex.com/realtime'

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
        if response['info']
          p response['info']
          to_data = {
            op: 'subscribe',
            args: ['orderBookL2:XBTUSD']
          }
          ws.send(to_data.to_json)
        elsif response['success']
          p "#{response['subscribe']} subscribed"
        else
          case response['action']
          when 'partial'
            BitmexOrderBook.delete_all

            response['data'].each do |ob|
              BitmexOrderBook.create!(
                id: ob['id'],
                symbol: ob['symbol'],
                side: ob['side'],
                price: ob['price'],
                amount: ob['size']
              )
            end
          when 'insert'
            response['data'].each do |ob|
              BitmexOrderBook.create!(
                id: ob['id'],
                symbol: ob['symbol'],
                side: ob['side'],
                price: ob['price'],
                amount: ob['size']
              )
            end
          when 'update'
            response['data'].each do |ob|
              BitmexOrderBook.find(ob['id']).update!(amount: ob['size'])
            end
          when 'delete'
            response['data'].each do |ob|
              BitmexOrderBook.find(ob['id']).destroy!
            end
          else
            logger.error "Unsupport action #{response['action']}"
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
