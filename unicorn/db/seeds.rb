# frozen_string_literal: true

user = User.create!(email: 'yang@gmal.com', password: '123456', password_confirmation: '123456')
puts user.authenticate('123456')
