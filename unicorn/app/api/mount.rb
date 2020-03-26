# frozen_string_literal: true

class Mount < Grape::API
  PREFIX = '/api'

  cascade false

  mount V1::Mount => V1::Mount::API_VERSION
end
