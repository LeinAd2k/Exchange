package forms

import (
	"testing"

	"github.com/FlowerWrong/exchange/models"
	"github.com/devfeel/mapper"
	"github.com/shopspring/decimal"
)

func TestOrderFormMapper(t *testing.T) {
	obf := &OrderForm{
		Symbol:    "BTC_USD",
		OrderType: "limit",
		Side:      "Buy",
		Volume:    decimal.NewFromFloat(10.00),
		Price:     decimal.NewFromFloat(100.00),
	}
	ob := &models.Order{}
	mapper.AutoMapper(obf, ob)
	t.Log(obf)
	t.Log(ob)
	if obf.Symbol != ob.Symbol {
		t.Fatal("Wrong done id")
	}
}
