# frozen_string_literal: true

module Daemons
  class Base
    attr_reader :logger

    def initialize
      @logger = Rails.logger
    end

    def stop
      EventMachine.stop
    end

    def run
      EventMachine.run do
        begin
          process
        rescue StandardError => e
          raise e if is_db_connection_error?(e)
        end
      end
    end

    def process
      method_not_implemented
    end

    def is_db_connection_error?(exception)
      exception.is_a?(Mysql2::Error::ConnectionError) || exception.cause.is_a?(Mysql2::Error)
    end
  end
end
