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
func Settlement(trade *Trade, tx *gorm.DB) error {
	fund := &Fund{}
	tx.First(fund, trade.FundID)
	locked := trade.Volume.Mul(trade.Price)
	// BTC_USD 为例，购买动作即用USD买BTC
	{
		// 买方
		// USD减少
		accountRight := &Account{}
		FindAccountByUserIDAndCurrencyID(tx, accountRight, trade.BidUserID, fund.RightCurrencyID)
		accountRight.UnLock(locked)
		if err := tx.Model(&accountRight).Update("locked", accountRight.Locked).Error; err != nil {
			tx.Rollback()
			return err
		}

		// BTC增加
		accountLeft := &Account{}
		FindAccountByUserIDAndCurrencyID(tx, accountLeft, trade.BidUserID, fund.LeftCurrencyID)
		accountLeft.Balance = accountLeft.Balance.Add(trade.Volume)
		if err := tx.Model(&accountLeft).Update("balance", accountLeft.Balance).Error; err != nil {
			tx.Rollback()
			return err
		}
	}
	{
		// 卖方
		// USD增加
		accountRight := &Account{}
		FindAccountByUserIDAndCurrencyID(tx, accountRight, trade.AskUserID, fund.RightCurrencyID)
		accountRight.Balance = accountRight.Balance.Add(locked)
		if err := tx.Model(&accountRight).Update("balance", accountRight.Balance).Error; err != nil {
			tx.Rollback()
			return err
		}

		// BTC减少
		accountLeft := &Account{}
		FindAccountByUserIDAndCurrencyID(tx, accountLeft, trade.AskUserID, fund.LeftCurrencyID)
		accountLeft.UnLock(trade.Volume)
		if err := tx.Model(&accountLeft).Update("locked", accountLeft.Locked).Error; err != nil {
			tx.Rollback()
			return err
		}
	}
	return nil
}
