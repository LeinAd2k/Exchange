package dtos

import (
	"github.com/FlowerWrong/exchange/models"
	"github.com/shopspring/decimal"
)

// OrderDTO ...
type OrderDTO struct {
	models.BaseModel
	UserID    uint64          `json:"user_id"`
	FundID    string          `json:"fund_id"`
	State     uint            `json:"state"`
	OrderType string          `json:"order_type"`
	Side      string          `json:"side"`
	Volume    decimal.Decimal `json:"volume"`
	Price     decimal.Decimal `json:"price"`
}
