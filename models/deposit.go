package models

import "github.com/shopspring/decimal"

// Deposit ...
type Deposit struct {
	BaseModel
	AccountID  uint64
	Account    Account
	CurrencyID string
	Currency   Currency
	Amount     decimal.Decimal `json:"amount" sql:"DECIMAL(32,16)"`
	Fee        decimal.Decimal `json:"fee" sql:"DECIMAL(32,16)"`
}
