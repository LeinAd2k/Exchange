# frozen_string_literal: true

# start mysql
cmd = 'helm install stable/mysql'
output = `#{cmd}`
puts output

# start redis
cmd = 'helm install stable/redis'
output = `#{cmd}`
puts output

# start rabbitmq
cmd = 'helm install stable/rabbitmq'
output = `#{cmd}`
puts output

# start sentry
cmd = 'helm install --wait stable/sentry'
output = `#{cmd}`
puts output
