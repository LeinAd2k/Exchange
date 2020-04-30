# frozen_string_literal: true

class OrderBookClient
  attr_accessor :conn

  def initialize
    @conn = Faye::WebSocket::Client.new(ENV['ORDER_BOOK_DB_URL'], [])
  end

  def create(name)
    send_data = {
      cmd: 'create',
      payload: {
        name: name
      }
    }
    @conn.send(send_data.to_json)
  end

  def drop(name)
    send_data = {
      cmd: 'drop',
      payload: {
        name: name
      }
    }
    @conn.send(send_data.to_json)
  end

  def update(name, bids = [], asks = [])
    send_data = {
      cmd: 'update',
      payload: {
        name: name,
        bids: bids,
        asks: asks
      }
    }
    @conn.send(send_data.to_json)
  end

  def update_trades(name, trades = [])
    send_data = {
      cmd: 'update_trades',
      payload: {
        name: name,
        trades: trades
      }
    }
    @conn.send(send_data.to_json)
  end

  def fetch(name, side = nil, limit = nil)
    send_data = {
      cmd: 'get',
      payload: {
        name: name
      }
    }
    send_data[:payload][:side] = side if side.present?
    send_data[:payload][:limit] = limit if limit.present?
    @conn.send(send_data.to_json)
  end

  def sub(name)
    send_data = {
      cmd: 'sub',
      payload: {
        name: name
      }
    }
    @conn.send(send_data.to_json)
  end

  def unsub(name)
    send_data = {
      cmd: 'unsub',
      payload: {
        name: name
      }
    }
    @conn.send(send_data.to_json)
  end
end
