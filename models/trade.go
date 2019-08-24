package models

import "github.com/shopspring/decimal"

// Trade ...
type Trade struct {
	BaseModel
	AskUserID  uint64          `json:"ask_user_id"`
	BidUserID  uint64          `json:"bid_user_id"`
	AskOrderID uint64          `json:"ask_order_id"`
	BidOrderID uint64          `json:"bid_order_id"`
	Symbol     string          `json:"symbol"`
	FundID     uint64          `json:"fund_id"`
	Fund       Fund            `json:"-"`
	Volume     decimal.Decimal `json:"volume" sql:"DECIMAL(32,16)"`
	Price      decimal.Decimal `json:"price" sql:"DECIMAL(32,16)"`
	AskFee     decimal.Decimal `json:"ask_fee" sql:"DECIMAL(32,16)"`
	BidFee     decimal.Decimal `json:"bid_fee" sql:"DECIMAL(32,16)"`
}
