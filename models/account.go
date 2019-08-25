package models

import (
	"github.com/jinzhu/gorm"
	"github.com/shopspring/decimal"
)

// Account ...
type Account struct {
	BaseModel
	UserID     uint64          `json:"user_id"`
	User       User            `json:"-"`
	CurrencyID uint64          `json:"currency_id"`
	Currency   Currency        `json:"-"`
	Symbol     string          `json:"symbol"`
	Balance    decimal.Decimal `json:"balance" sql:"DECIMAL(32,16)"`
	Locked     decimal.Decimal `json:"locked" sql:"DECIMAL(32,16)"`
}

// Lock without db update
func (a *Account) Lock(money decimal.Decimal) {
	a.Locked = a.Locked.Add(money)
	a.Balance = a.Balance.Sub(money)
}

// UnLock without db update
func (a *Account) UnLock(money decimal.Decimal) {
	a.Locked = a.Locked.Sub(money)
}

// Amount ...
func (a *Account) Amount() decimal.Decimal {
	return a.Balance.Add(a.Locked)
}

// FindAccountByUserIDAndCurrencyID ...
func FindAccountByUserIDAndCurrencyID(tx *gorm.DB, account *Account, userID, currencyID uint64) {
	tx.Where("user_id = ? and currency_id = ?", userID, currencyID).First(account)
}

// Settlement 账户结算
func Settlement(trade *Trade, fund *Fund, tx *gorm.DB) error {
	locked := trade.Volume.Mul(trade.Price)
	// BTC_USD 为例，购买动作即用USD买BTC
	{
		// 买方
		// USD减少
		bidAccountRight := &Account{}
		FindAccountByUserIDAndCurrencyID(tx, bidAccountRight, trade.BidUserID, fund.RightCurrencyID)
		bidAccountRight.UnLock(locked)
		if err := tx.Model(&bidAccountRight).Update("locked", bidAccountRight.Locked).Error; err != nil {
			tx.Rollback()
			return err
		}

		// BTC增加
		bidAccountLeft := &Account{}
		FindAccountByUserIDAndCurrencyID(tx, bidAccountLeft, trade.BidUserID, fund.LeftCurrencyID)
		bidAccountLeft.Balance = bidAccountLeft.Balance.Add(trade.Volume)
		if err := tx.Model(&bidAccountLeft).Update("balance", bidAccountLeft.Balance).Error; err != nil {
			tx.Rollback()
			return err
		}
	}
	{
		// 卖方
		// USD增加
		askAccountRight := &Account{}
		FindAccountByUserIDAndCurrencyID(tx, askAccountRight, trade.AskUserID, fund.RightCurrencyID)
		askAccountRight.Balance = askAccountRight.Balance.Add(locked)
		if err := tx.Model(&askAccountRight).Update("balance", askAccountRight.Balance).Error; err != nil {
			tx.Rollback()
			return err
		}

		// BTC减少
		askAccountLeft := &Account{}
		FindAccountByUserIDAndCurrencyID(tx, askAccountLeft, trade.AskUserID, fund.LeftCurrencyID)
		askAccountLeft.UnLock(trade.Volume)
		if err := tx.Model(&askAccountLeft).Update("locked", askAccountLeft.Locked).Error; err != nil {
			tx.Rollback()
			return err
		}
	}
	return nil
}
