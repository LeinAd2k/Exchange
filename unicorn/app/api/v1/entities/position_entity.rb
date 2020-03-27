# frozen_string_literal: true

# https://www.okex.com/docs/zh/#swap-swap---hold_information
# https://www.bitmex.com/api/explorer/#!/Position/Position_get
# https://github.com/BaseFEX/basefex-api-docs/blob/master/api-doc_zh.md
module V1
  module Entities
    class PositionEntity < BaseEntity
      expose :account_id, documentation: { type: 'String', desc: 'Your unique account ID' }
      expose :symbol, documentation: { type: 'String', desc: '合约ID' }
      expose :currency_id, documentation: { type: 'String', desc: '保证金币种' }
      expose :underlying, documentation: { type: 'String', desc: 'Meta data of the symbol' }
      expose :quote_currency, documentation: { type: 'String', desc: 'Meta data of the symbol, All prices are in the quoteCurrency' }
      expose :commission, documentation: { type: 'String', desc: 'The maximum of the maker, taker, and settlement fee' }
      expose :init_margin_req, documentation: { type: 'String', desc: "The initial margin requirement. This will be at least the symbol's default initial maintenance margin, but can be higher if you choose lower leverage" }
      expose :maint_margin_req, documentation: { type: 'String', desc: "维持保证金率?The maintenance margin requirement. This will be at least the symbol's default maintenance maintenance margin, but can be higher if you choose a higher risk limit." }
      expose :risk_limit, documentation: { type: 'String', desc: '风险限额This is a function of your maintMarginReq' }
      expose :leverage, documentation: { type: 'String', desc: '1 / initMarginReq' }
      expose :cross_margin, documentation: { type: 'String', desc: '是否全仓' }
      expose :deleverage_percentile, documentation: { type: 'String', desc: 'Indicates where your position is in the ADL queue' }
      expose :rebalanced_pnl, documentation: { type: 'String', desc: 'The value of realised PNL that has transferred to your wallet for this position' }
      expose :prev_realised_pnl, documentation: { type: 'String', desc: 'The value of realised PNL that has transferred to your wallet for this position since the position was closed' }
      expose :current_qty, documentation: { type: 'String', desc: 'The current position amount in contracts' }
      expose :current_cost, documentation: { type: 'String', desc: 'The current cost of the position in the settlement currency of the symbol (currency)' }
      expose :current_comm, documentation: { type: 'String', desc: 'The current commission of the position in the settlement currency of the symbol (currency)' }
      expose :realised_cost, documentation: { type: 'String', desc: 'The realised cost of this position calculated with regard to average cost accounting' }
      expose :unrealised_cost, documentation: { type: 'String', desc: 'currentCost - realisedCost' }
      expose :gross_open_cost, documentation: { type: 'String', desc: 'The absolute value of your open orders for this symbol' }
      expose :gross_open_premium, documentation: { type: 'String', desc: 'The amount your bidding above the mark price in the settlement currency of the symbol (currency)' }
      expose :mark_price, documentation: { type: 'String', desc: '标记价格' }
      expose :mark_value, documentation: { type: 'String', desc: 'The currentQty at the mark price in the settlement currency of the symbol (currency)' }
      expose :home_notional, documentation: { type: 'String', desc: 'Value of position in units of underlying' }
      expose :foreign_notional, documentation: { type: 'String', desc: 'Value of position in units of quoteCurrency' }
      expose :realised_pnl, documentation: { type: 'String', desc: '已实现盈亏' }
      expose :unrealised_gross_pnl, documentation: { type: 'String', desc: 'markValue - unrealisedCost' }
      expose :unrealised_pnl, documentation: { type: 'String', desc: '未实现盈亏' }
      expose :liquidation_price, documentation: { type: 'String', desc: '预估强平价' }
      expose :bankrupt_price, documentation: { type: 'String', desc: 'Once markPrice reaches this price, this position will have no equity' }

      with_options(format_with: :iso_timestamp) do
        expose :created_at
        expose :updated_at
      end
    end
  end
end
