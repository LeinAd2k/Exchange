package models

import (
	"strconv"

	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/services/matching"
	"github.com/shopspring/decimal"
)

const (
	// Wait order
	Wait = iota
	// Pending order
	Pending
	// Cancelling order
	Cancelling
	// Canceled order
	Canceled
	// Done order
	Done
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

func CreateOrder(order *Order, account *Account, locked decimal.Decimal) error {
	tx := db.ORM().Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := tx.Error; err != nil {
		return err
	}

	if err := tx.Create(order).Error; err != nil {
		tx.Rollback()
		return err
	}

	account.Lock(locked)
	if err := tx.Save(&account).Error; err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// Transaction ...
func Transaction(order *Order, done []*matching.Order) error {
	tx := db.ORM().Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()
	if err := tx.Error; err != nil {
		return err
	}

	for _, matchingOrderDone := range done {
		id := matchingOrderDone.IntID()
		// 对方记录
		orderDone := &Order{}
		tx.Find(orderDone, id)
		orderDone.Volume = orderDone.Volume.Sub(matchingOrderDone.Quantity())
		if orderDone.Volume.Sign() == 0 {
			orderDone.State = Done
		}
		if err := tx.Save(orderDone).Error; err != nil {
			tx.Rollback()
			return err
		}

		// 当前用户记录
		order.Volume = order.Volume.Sub(matchingOrderDone.Quantity())
		if order.Volume.Sign() == 0 {
			order.State = Done
		}
		if err := tx.Save(order).Error; err != nil {
			tx.Rollback()
			return err
		}

		// 交易记录
		trade := &Trade{}
		trade.Symbol = order.Symbol
		trade.FundID = order.FundID
		trade.Volume = matchingOrderDone.Quantity()
		trade.Price = matchingOrderDone.Price()
		if order.Side == "buy" {
			trade.BidUserID = order.UserID
			trade.BidOrderID = order.ID
			trade.AskUserID = orderDone.UserID
			trade.AskOrderID = orderDone.ID
		} else {
			trade.BidUserID = orderDone.UserID
			trade.BidOrderID = orderDone.ID
			trade.AskUserID = order.UserID
			trade.AskOrderID = order.ID
		}
		if err := tx.Create(trade).Error; err != nil {
			tx.Rollback()
			return err
		}

		// 账户结算
		err := Settlement(trade, tx)
		if err != nil {
			return err
		}
	}

	if order.OrderType == "market" {
		order.State = Done
		if err := tx.Save(order).Error; err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit().Error
}
