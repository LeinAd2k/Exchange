package models

import (
	"github.com/FlowerWrong/exchange/db"
	"github.com/shopspring/decimal"
)

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
	TakerFee   decimal.Decimal `json:"taker_fee" sql:"DECIMAL(32,16)"`
	MakerFee   decimal.Decimal `json:"maker_fee" sql:"DECIMAL(32,16)"`
}

// CurrentPrice 返回最新成交价
func CurrentPrice(symbol string) decimal.Decimal {
	var trade Trade
	err := db.ORM().Where("symbol = ?", symbol).Last(&trade).Error
	if err != nil {
		return decimal.NewFromFloat(0)
	}

	return trade.Price
}
