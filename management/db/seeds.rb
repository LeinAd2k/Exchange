# frozen_string_literal: true

coins = %w[btc eth usd]

coins.each do |c|
  Currency.create!(id: c)
end

%w[btc_usd eth_usd].each do |f|
  Fund.create!(
    id: f,
    name: f,
    base: f.split('_')[0],
    quote: f.split('_')[1]
  )
end

user1 = User.new(
  name: 't1',
  password: '111111',
  password_confirmation: '111111',
  email: 't1@gmail.com',
  role: 'customer',
  address: '北京朝阳'
)
user1.save!

user2 = User.new(
  name: 't2',
  password: '111111',
  password_confirmation: '111111',
  email: 't2@gmail.com',
  role: 'customer',
  address: '北京朝阳'
)
user2.save!

Currency.all.each do |c|
  Account.create!(
    user_id: user1.id,
    currency_id: c.id,
    balance: 100_000_000,
    locked: 0
  )

  Account.create!(
    user_id: user2.id,
    currency_id: c.id,
    balance: 100_000_000,
    locked: 0
  )
end
