# frozen_string_literal: true

class KController < ApplicationController
  def index
    case params[:ex]
    when 'binance'
      render json: fetch_k(params[:symbol], params[:interval], params[:limit], params[:start_time], params[:end_time])
    end
  end

  private

  def fetch_k(symbol, interval, limit = 1000, start_time = nil, end_time = nil)
    path = '/api/v3/klines'
    req_p = { symbol: symbol, interval: interval, limit: limit }
    req_p.merge!(startTime: start_time) if start_time.present?
    req_p.merge!(endTime: end_time) if end_time.present?
    ob_resp = conn.get(path) do |req|
      req.params = req_p
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
