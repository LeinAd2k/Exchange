# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
  end

  config.before(:each) do
    DatabaseCleaner.start
    Rails.cache.clear
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
