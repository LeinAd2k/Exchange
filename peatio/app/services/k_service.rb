# frozen_string_literal: true

class KService
  class << self
    K_TIMEOUT = 15

    def fetch_k(ex, symbol, interval, limit = 1000, start_time = nil, end_time = nil)
      case ex
      when :bitfinex
        # https://docs.bitfinex.com/reference#rest-public-candles
        path = "/v2/candles/trade:#{interval}:#{symbol}/hist"
        req_p = { limit: limit, sort: -1 }
        req_p.merge!(start: start_time) if start_time.present?
        req_p.merge!(end: end_time) if end_time.present?
        ob_resp = conn(ex).get(path) do |req|
          req.params = req_p
          req.options.timeout = K_TIMEOUT
        end
        ob_resp.body.reverse
      when :binance
        path = exchanges[ex][:k_path]
        req_p = { symbol: symbol, interval: interval, limit: limit }
        req_p.merge!(startTime: start_time) if start_time.present?
        req_p.merge!(endTime: end_time) if end_time.present?
        ob_resp = conn(ex).get(path) do |req|
          req.params = req_p
          req.options.timeout = K_TIMEOUT
        end
        ob_resp.body.map { |e| [e[0], e[1], e[4], e[2], e[3], e[5]] }
      end
      # timestamp, open, close, high, low, volume
    end

    def conn(exchange)
      url = KService.exchanges[exchange][:base_url]
      @conn ||= begin
        Faraday.ignore_env_proxy = true
        Faraday.new(url, proxy: ENV['HTTP_PROXY_URL']) do |f|
          f.request :url_encoded
          f.response :json, content_type: /\bjson$/

          # Last middleware must be the adapter:
          f.adapter Faraday.default_adapter
        end
      end
    end

    def exchanges
      {
        binance: {
          api_version: 3,
          base_url: 'https://api.binance.com',
          k_path: '/api/v3/klines'
        },
        bitfinex: {
          api_version: 2,
          base_url: 'https://api-pub.bitfinex.com'
        }
      }
    end
  end
end
