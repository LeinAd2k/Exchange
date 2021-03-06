# frozen_string_literal: true

module V1
  module Helpers
    module OrderHelpers
      def build_order(attrs)
        (attrs[:side] == 'sell' ? OrderAsk : OrderBid).new \
          state: ::Order::PENDING,
          member: current_user,
          ask: current_market&.base_unit,
          bid: current_market&.quote_unit,
          market: current_market,
          ord_type: attrs[:ord_type] || 'limit',
          price: attrs[:price],
          volume: attrs[:volume],
          origin_volume: attrs[:volume]
      end

      def check_balance(order)
        current_user.get_account(order.currency).balance >= order.locked
      end

      def create_order(attrs)
        create_order_errors = {
          ::Account::AccountError => 'market.account.insufficient_balance',
          ::Order::InsufficientMarketLiquidity => 'market.order.insufficient_market_liquidity',
          ActiveRecord::RecordInvalid => 'market.order.invalid_volume_or_price'
        }

        order = build_order(attrs)
        submit_order(order)
        order
        # TODO: Make more specific error message for ActiveRecord::RecordInvalid.
      rescue StandardError => e
        if create_order_errors.include?(e.class)
          report_api_error(e, request)
        else
          report_exception(e)
        end

        message = create_order_errors.fetch(e.class, 'market.order.create_error')
        error!({ errors: [message] }, 422)
      end

      def submit_order(order)
        order.locked = order.origin_locked = order.compute_locked
        raise ::Account::AccountError unless check_balance(order)

        order.save!

        AMQP::Queue.enqueue(:order_processor,
                            { action: 'submit', order: order.attributes },
                            { persistent: false })

        # Notify third party trading engine about order submit.
        AMQP::Queue.enqueue(:events_processor,
                            subject: :submit_order,
                            payload: order.as_json_for_events_processor)
      end

      def cancel_order(order)
        AMQP::Queue.enqueue(:matching, action: 'cancel', order: order.to_matching_attributes)

        # Notify third party trading engine about order stop.
        AMQP::Queue.enqueue(:events_processor,
                            subject: :stop_order,
                            payload: order.as_json_for_events_processor)
      end

      def order_param
        params[:order_by].downcase == 'asc' ? 'id asc' : 'id desc'
      end
    end
  end
end
