# frozen_string_literal: true

module V1
  class Sessions < Grape::API
    desc 'Login'
    params do
      requires :email, allow_blank: false, type: String, desc: 'User email'
      requires :password, allow_blank: false, type: String, desc: 'User password'
    end
    post '/login' do
      user = User.find_by(email: params[:email])
      if user&.authenticate(params[:password])
        exp = Time.current.to_i + 24 * 3600
        exp_payload = { data: {
          id: user.id,
          email: user.email
        }, exp: exp }
        present :token, JWT.encode(exp_payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM'])
      else
        error!({ msg: 'Invalid email or password' }, 400)
      end
    end
  end
end
