# frozen_string_literal: true

module Daemons
  class Binance < Base
    def process
      url = 'wss://stream.binance.com:9443/ws/btcusdt@depth@100ms'
      binance_url = 'https://www.binance.com'
      order_book_path = '/api/v3/depth'

      Faraday.ignore_env_proxy = true
      conn = Faraday.new(binance_url, proxy: ENV['HTTP_PROXY_URL']) do |f|
        f.request :url_encoded
        f .response :json, content_type: /\bjson$/

        # Last middleware must be the adapter:
        f.adapter Faraday.default_adapter
      end

      ob_resp = conn.get(order_book_path) do |req|
        req.params = { symbol: 'BTCUSDT', limit: 1000 }
      end
      ob_resp.body

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
