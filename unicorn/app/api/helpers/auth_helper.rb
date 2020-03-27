# frozen_string_literal: true

module Helpers
  module AuthHelper
    def current_user
      return @current_user if @current_user.present?

      return if headers['Authorization'].blank?

      _, token = headers['Authorization'].split(' ')
      begin
        decoded_token = JWT.decode(token, ENV['JWT_SECRET'], true, { algorithm: ENV['JWT_ALGORITHM'] })
        @current_user ||= User.find_by(email: decoded_token[0]['data']['email'])
      rescue JWT::ExpiredSignature => e
        Rails.logger.error e.message
        nil
      rescue JWT::DecodeError => e
        Rails.logger.error e.message
        nil
      end
    end

    def authenticate!
      error!({ msg: '401 Unauthorized' }, 401) unless current_user
    end
  end
end
