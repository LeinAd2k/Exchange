# frozen_string_literal: true

class KController < ApplicationController
  def index
    case params[:ex]
    when 'binance'
      render json: fetch_k
    end
  end

  private

  def fetch_k
    path = '/api/v3/klines'
    ob_resp = conn.get(path) do |req|
      req.params = { symbol: 'BTCUSDT', interval: '1m' }
    end
    ob_resp.body
  end

  def conn
    url = 'https://api.binance.com'
    @conn ||= begin
      Faraday.ignore_env_proxy = true
      Faraday.new(url, proxy: ENV['HTTP_PROXY_URL']) do |f|
        f.request :url_encoded
        f .response :json, content_type: /\bjson$/

        # Last middleware must be the adapter:
        f.adapter Faraday.default_adapter
      end
    end
  end
end
