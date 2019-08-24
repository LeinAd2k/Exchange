package models

import (
	"strconv"

	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/services/matching"
	"github.com/shopspring/decimal"
)

// Order ...
type Order struct {
	BaseModel
	UserID    uint64          `json:"user_id"`
	User      User            `json:"-"`
	Symbol    string          `json:"symbol"`
	FundID    uint64          `json:"fund_id"`
	Fund      Fund            `json:"-"`
	State     uint            `gorm:"default:0" json:"state"` // wait pending done cancel reject
	OrderType string          `json:"order_type"`             // market or limit
	Side      string          `json:"side"`                   // sell or buy
	Volume    decimal.Decimal `json:"volume" sql:"DECIMAL(32,16)"`
	Price     decimal.Decimal `json:"price" sql:"DECIMAL(32,16)"`
	AskFee    decimal.Decimal `json:"ask_fee" sql:"DECIMAL(32,16)"`
	BidFee    decimal.Decimal `json:"bid_fee" sql:"DECIMAL(32,16)"`
}

// CurrentPrice 返回最新成交价
func CurrentPrice(symbol string) decimal.Decimal {
	var order Order
	db.ORM().Where("symbol = ?", symbol).Last(&order)
	return order.Price
}

// StrID return string id
func (o *Order) StrID() string {
	return strconv.FormatUint(o.ID, 10)
}

// Transaction ...
func Transaction(order *Order, done []*matching.Order) error {
	return nil
}
