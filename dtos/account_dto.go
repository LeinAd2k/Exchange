package dtos

import (
	"github.com/FlowerWrong/exchange/models"
	"github.com/shopspring/decimal"
)

// AccountDTO ...
type AccountDTO struct {
	models.BaseModel
	UserID     uint64          `json:"user_id"`
	CurrencyID uint64          `json:"currency_id"`
	Symbol     string          `json:"symbol"`
	Balance    decimal.Decimal `json:"balance" sql:"DECIMAL(32,16)"`
	Locked     decimal.Decimal `json:"locked" sql:"DECIMAL(32,16)"`
}
