package models

import (
	"strconv"

	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/log"
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
	Action       string          `json:"action"` // create/update/cancel
	UserID       uint64          `json:"user_id"`
	User         User            `json:"-"`
	FundID       string          `json:"fund_id"`
	Fund         Fund            `json:"-"`
	State        uint            `gorm:"default:0" json:"state"` // wait pending done cancel reject
	OrderType    string          `json:"order_type"`             // market or limit
	Side         string          `json:"side"`                   // sell or buy
	Volume       decimal.Decimal `json:"volume" sql:"DECIMAL(32,16)"`
	OriginVolume decimal.Decimal `json:"origin_volume" sql:"DECIMAL(32,16)"`
	Price        decimal.Decimal `json:"price" sql:"DECIMAL(32,16)"`
	TakerFee     decimal.Decimal `json:"taker_fee" sql:"DECIMAL(32,16)"`
	MakerFee     decimal.Decimal `json:"maker_fee" sql:"DECIMAL(32,16)"`
}

// StrID return string id
func (o *Order) StrID() string {
	return strconv.FormatUint(o.ID, 10)
}

// LoadOrdersToMatchingEngine ...
func LoadOrdersToMatchingEngine(obm *matching.OrderBookManager) {
	var orders []Order
	db.ORM().Where("state = ?", Wait).Order("created_at asc").Find(&orders)
	for _, order := range orders {
		ob := obm.Get(order.FundID)
		side := matching.Str2Side(order.Side)
		if order.OrderType == "limit" {
			ob.ProcessLimitOrder(side, order.StrID(), order.Volume, order.Price)
		} else if order.OrderType == "market" {
			ob.ProcessMarketOrder(side, order.Volume)
		}
	}

	var funds []Fund
	db.ORM().Find(&funds)
	for _, fund := range funds {
		ob := obm.Get(fund.ID)
		err := ob.Backup(fund.ID)
		if err != nil {
			log.Println(err)
		}

		err = ob.BackupDepth(fund.ID)
		if err != nil {
			log.Println(err)
		}
	}
}

// CreateOrder ...
func (o *Order) CreateOrder(account *Account, locked decimal.Decimal) error {
	tx := db.ORM().Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := tx.Error; err != nil {
		return err
	}

	if err := tx.Create(o).Error; err != nil {
		tx.Rollback()
		return err
	}

	accountUpdate := Account{}
	accountUpdate.Locked = account.Locked.Add(locked)
	accountUpdate.Balance = account.Balance.Sub(locked)
	if err := tx.Model(account).Updates(accountUpdate).Error; err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}

// CancellingOrder ...
func (o *Order) CancellingOrder() error {
	if o.State != Cancelling {
		return ErrCancelNoneCancellingOrder
	}
	if o.OrderType == "market" {
		return ErrCancelMarketOrder
	}

	tx := db.ORM().Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
		}
	}()

	if err := tx.Error; err != nil {
		return err
	}

	orderUpdate := Order{State: Canceled}
	if err := tx.Model(&o).Updates(orderUpdate).Error; err != nil {
		tx.Rollback()
		return err
	}

	fund := &Fund{}
	tx.First(&fund, "id = ?", o.FundID)

	account := &Account{}
	accountUpdate := Account{}
	if o.Side == "buy" {
		FindAccountByUserIDAndCurrencyID(tx, account, o.UserID, fund.Quote)
		locked := o.Volume.Mul(o.Price)
		accountUpdate.Locked = account.Locked.Sub(locked)
		accountUpdate.Balance = account.Balance.Add(locked)
	} else {
		FindAccountByUserIDAndCurrencyID(tx, account, o.UserID, fund.Base)
		locked := o.Volume
		accountUpdate.Locked = account.Locked.Sub(locked)
		accountUpdate.Balance = account.Balance.Add(locked)
	}
	if err := tx.Model(account).Updates(accountUpdate).Error; err != nil {
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
	order.State = Pending

	fund := &Fund{}
	tx.Where("id = ?", order.FundID).First(fund)

	for _, matchingOrderDone := range done {
		id := matchingOrderDone.IntID()
		orderDone := &Order{}
		tx.Find(orderDone, id)

		{
			// 对方记录
			orderDoneUpdate := Order{}
			orderDoneUpdate.Volume = orderDone.Volume.Sub(matchingOrderDone.Quantity())
			if orderDoneUpdate.Volume.Sign() == 0 {
				orderDoneUpdate.State = Done
			}
			if err := tx.Model(orderDone).Updates(orderDoneUpdate).Error; err != nil {
				tx.Rollback()
				return err
			}
		}

		{
			// 当前用户记录
			if order.OrderType == "market" && order.Side == "buy" {
				// eg: BTC_USD 市价买单存放的是USD总量
				order.Volume = order.Volume.Sub(matchingOrderDone.Quantity().Mul(matchingOrderDone.Price()))
			} else {
				order.Volume = order.Volume.Sub(matchingOrderDone.Quantity())
			}
			if order.Volume.Sign() == 0 {
				order.State = Done
			}
		}

		{
			// 交易记录
			trade := &Trade{}
			trade.FundID = fund.ID
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
			err := Settlement(trade, fund, tx)
			if err != nil {
				return err
			}
		}
	}

	if order.OrderType == "market" && order.State != Done {
		order.State = Done

		account := &Account{}
		if order.Side == "buy" {
			FindAccountByUserIDAndCurrencyID(tx, account, order.UserID, fund.Quote)
		} else {
			FindAccountByUserIDAndCurrencyID(tx, account, order.UserID, fund.Base)
		}
		accountUpdate := Account{}
		accountUpdate.Locked = account.Locked.Sub(order.Volume)
		accountUpdate.Balance = account.Balance.Add(order.Volume)
		if err := tx.Model(&account).Updates(accountUpdate).Error; err != nil {
			tx.Rollback()
			return err
		}
	}
	if err := tx.Save(order).Error; err != nil {
		tx.Rollback()
		return err
	}

	return tx.Commit().Error
}
