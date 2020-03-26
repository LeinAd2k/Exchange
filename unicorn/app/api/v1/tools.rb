# frozen_string_literal: true

module V1
  class Tools < Grape::API
    desc 'Get server current time, in seconds since Unix epoch.'
    get '/timestamp' do
      ::Time.now.iso8601
    end
  end
end
