# frozen_string_literal: true

module API
  module V1
    class Mount < Grape::API
      API_VERSION = 'v1'

      format         :json
      content_type   :json, 'application/json'
      default_format :json

      do_not_route_options!

      # https://github.com/aserafin/grape_logging#logging-via-rails-instrumentation
      use GrapeLogging::Middleware::RequestLogger,
          instrumentation_key: 'grape_key',
          include: [GrapeLogging::Loggers::Response.new,
                    GrapeLogging::Loggers::FilterParameters.new]
    end
  end
end
