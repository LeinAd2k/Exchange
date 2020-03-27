# frozen_string_literal: true

module V1
  module Entities
    class InstrumentEntity < BaseEntity
      expose :id
      expose :name
      expose :base
      expose :quote
      expose :settlement

      with_options(format_with: :iso_timestamp) do
        expose :created_at
        expose :updated_at
      end
    end
  end
end
