# frozen_string_literal: true

module V1
  class Instruments < Grape::API
    desc 'Get instrument(s)'
    params do
      optional :symbol, allow_blank: false, type: String, desc: 'Instrument symbol name'
    end
    get '/instruments' do
      instruments = if params[:symbol]
                      Instrument.where(id: params[:symbol])
                    else
                      Instrument.all
                    end

      present instruments, with: V1::Entities::InstrumentEntity
    end
  end
end
