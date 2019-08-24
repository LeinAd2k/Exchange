package models

import "errors"

var (
	ErrWithoutEnoughMoney        = errors.New("orderbook: without enough money")
	ErrCancelNoneWaitOrder       = errors.New("Can not cancel none wait state order")
	ErrCancelNoneCancellingOrder = errors.New("Can not cancel none calcelling state order")
	ErrCancelMarketOrder         = errors.New("Can not cancel market order")
	ErrUserNotFound              = errors.New("Current user not found")
)
