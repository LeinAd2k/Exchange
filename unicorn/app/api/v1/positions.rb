# frozen_string_literal: true

module V1
  class Positions < Grape::API
    desc 'Get your positions'
    params do
      requires :symbol, allow_blank: false, type: String, desc: 'Market symbol name'
    end
    get '/positions' do
    end

    desc 'Enable isolated margin or cross margin per-position'
    params do
      requires :symbol, allow_blank: false, type: String, desc: 'Market symbol name'
    end
    post '/positions/isolate' do
    end

    desc 'Choose leverage for a position'
    params do
      requires :symbol, allow_blank: false, type: String, desc: 'Market symbol name'
    end
    post '/positions/leverage' do
    end

    desc 'Update your risk limit'
    params do
      requires :symbol, allow_blank: false, type: String, desc: 'Market symbol name'
    end
    post '/positions/risk-limit' do
    end

    desc 'Transfer equity in or out of a position'
    params do
      requires :symbol, allow_blank: false, type: String, desc: 'Market symbol name'
    end
    post '/positions/transfer-margin' do
    end
  end
end
