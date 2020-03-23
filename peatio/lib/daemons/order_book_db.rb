# frozen_string_literal: true

require File.join(ENV.fetch('RAILS_ROOT'), 'config', 'environment')

class OrderBookDBManager
  attr_accessor :dbs

  def initialize
    @dbs = {}
  end

  def find(name)
    @dbs[name]
  end

  def create(name)
    puts "Create order book #{name}"

    @dbs[name] = OrderBookDB.new(name)
  end

  def drop(name)
    puts "Drop order book #{name}"

    @dbs[name]&.bids&.clear
    @dbs[name]&.asks&.clear
    @dbs.delete(name)
  end

  def get_depth(name, side)
    db = find(name)
    case side
    when 'Sell'
      db.asks.to_a
    when 'Buy'
      db.bids.to_a.reverse
    end
  end

  def get_depth_with_precision(name, side, agg_precision)
    round_option = side == 'Sell' ? BigDecimal::ROUND_UP : BigDecimal::ROUND_DOWN
    precision = agg_precision.positive? ? agg_precision : 0
    depth = Hash.new { |h, k| h[k] = 0 }
    db = find(name)

    db.send((side == 'Sell' ? 'asks' : 'bids').to_s).each do |price_level|
      depth[price_with_precision(price_level[0], precision, round_option)] += price_level[1]
    end

    depth.delete_if { |_, value| value.zero? }
    depth = depth.stringify_keys.to_a
    depth.reverse! if side == 'Buy'
    depth
  end

  private

  def price_with_precision(price, precision, round_option)
    result = price.round(precision, round_option)
    result = result.truncate(precision).to_i unless precision.positive?
    result.to_s
  end
end

class OrderBookDB
  attr_accessor :name, :bids, :asks, :pubsub

  def initialize(name)
    @name = name
    @bids = RBTree.new
    @asks = RBTree.new
    @pubsub = {}
  end

  def fetch(side = nil, limit = nil)
    res = { name: @name }
    if side.present?
      case side
      when 'Sell'
        res[:asks] = @asks.to_a
      when 'Buy'
        res[:bids] = @bids.to_a.reverse
      end
    else
      res[:asks] = @asks.to_a
      res[:bids] = @bids.to_a.reverse
    end
    if limit.present?
      res[:asks] = res[:asks][0, limit] if res[:asks].present?
      res[:bids] = res[:bids][0, limit] if res[:bids].present?
    end
    res
  end

  def update(payload)
    payload['bids'].each do |ob|
      price = ob[0].to_d
      amount = ob[1].to_d
      amount.zero? ? @bids.delete(price) : @bids[price] = amount
    end

    payload['asks'].each do |ob|
      price = ob[0].to_d
      amount = ob[1].to_d
      amount.zero? ? @asks.delete(price) : @asks[price] = amount
    end

    payload['cmd'] = 'update'
    @pubsub.each do |conn, ready|
      if ready
        conn.send(payload.to_json)
      else
        partial_data = { name: @name, cmd: 'partial', bids: @bids.to_a, asks: @asks.to_a }
        conn.send(partial_data.to_json)
        @pubsub[conn] = true
      end
    end
  end

  def sub(conn)
    puts "#{conn} subscribed #{@name}"

    @pubsub[conn] = false
  end

  def unsub(conn)
    puts "#{conn} unsubscribed #{@name}"

    @pubsub.delete(conn)
  end
end

$db_manager = OrderBookDBManager.new
PORT = 6389
EM.run do
  Signal.trap('INT')  { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }

  EM::WebSocket.run(host: '0.0.0.0', port: PORT) do |ws|
    ws.onopen do |_handshake|
      puts 'WebSocket connection open'
    end

    ws.onclose { puts 'Connection closed' }

    ws.onmessage do |msg|
      puts "Received message: #{msg}"

      data = JSON.parse(msg)
      db_name = data['payload']['name']
      case data['cmd']
      when 'create'
        $db_manager.create(db_name)
      when 'drop'
        $db_manager.drop(db_name)
      when 'update'
        $db_manager.find(db_name).update(data['payload'])
      when 'get'
        $db_manager.find(db_name).fetch(data['payload']['side'], data['payload']['limit'])
      when 'sub'
        $db_manager.find(db_name).sub(ws)
      when 'unsub'
        $db_manager.find(db_name).unsub(ws)
      else
        raise "Unsupport cmd #{data['cmd']}"
      end
    end
  end

  puts "Order book database listen on #{PORT}"
end
