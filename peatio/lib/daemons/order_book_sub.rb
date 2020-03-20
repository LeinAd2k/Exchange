# frozen_string_literal: true

require File.join(ENV.fetch('RAILS_ROOT'), 'config', 'environment')

EventMachine.run do
  ob = OrderBookClient.new

  ob.conn.on :open do |_event|
    p [:open]

    name = 'bitmex_XBTUSD'
    ob.sub(name)
  end

  ob.conn.on :message do |event|
    ap JSON.parse(event.data)
  end

  ob.conn.on :close do |event|
    p [:close, event.code, event.reason]
    ob.conn = nil
  end
end
