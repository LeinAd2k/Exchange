# frozen_string_literal: true

module V1
  class Liquidations < Grape::API
    desc 'Get liquidation orders'
    params do
      requires :symbol, allow_blank: false, type: String, desc: 'Instrument symbol name'
    end
    get '/liquidations' do
    end
  end
end
