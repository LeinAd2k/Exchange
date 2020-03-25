# frozen_string_literal: true

# Subscribe to grape request and log with Rails.logger
ActiveSupport::Notifications.subscribe('grape_key') do |_name, _starts, _ends, _notification_id, payload|
  Rails.logger.info payload
end
