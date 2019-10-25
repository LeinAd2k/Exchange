package models

import "github.com/shopspring/decimal"

// Position ...
type Position struct {
	BaseModel
	FundID            string          `json:"fund_id"`
	Fund              Fund            `json:"-"`
	AccountID         uint64          `json:"account_id"`
	Account           Account         `json:"-"`
	OpenAveragePrice  decimal.Decimal `json:"open_average_price" sql:"DECIMAL(32,16)"`
	CloseAveragePrice decimal.Decimal `json:"close_average_price" sql:"DECIMAL(32,16)"`
	LiquidationPrice  decimal.Decimal `json:"liquidation_price" sql:"DECIMAL(32,16)"`
	OpenType          string          `json:"open_type"`
	Side              string          `json:"side"` // sell or buy
	State             uint            `gorm:"default:0" json:"state"`
	OpenVolume        uint64          `json:"open_volume"`
	CloseVolume       uint64          `json:"close_volume"`
}
