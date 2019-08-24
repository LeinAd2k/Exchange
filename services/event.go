package services

import (
	"encoding/json"

	"github.com/FlowerWrong/exchange/models"
)

// Event ...
type Event struct {
	Name string          `json:"name"`
	Data json.RawMessage `json:"data"`
}

// OrderEvent ...
func OrderEvent(order *models.Order, eventName string) []byte {
	b, err := json.Marshal(order)
	if err != nil {
		panic(err)
	}
	raw := json.RawMessage(b)
	event := &Event{Name: eventName, Data: raw}
	data, err := json.Marshal(event)
	if err != nil {
		panic(err)
	}
	return data
}
