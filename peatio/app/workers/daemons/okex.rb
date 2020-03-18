# frozen_string_literal: true

module Daemons
  class Okex < Base
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
        ap response
      end

      ws.on :close do |event|
        p [:close, event.code, event.reason]
        ws = nil
      end
    end
  end
end
