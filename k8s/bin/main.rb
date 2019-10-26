#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thor'

class K8s < Thor
  desc 'foo', 'Prints bar'
  def foo
    puts 'bar'
  end
end

K8s.start
