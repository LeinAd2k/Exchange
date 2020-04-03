# frozen_string_literal: true

Rails.application.routes.draw do
  get '/k/:ex', to: 'k#index'
end
