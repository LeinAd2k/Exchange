package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"runtime"
	"time"

	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/models"
	"github.com/FlowerWrong/exchange/services"
	"github.com/FlowerWrong/exchange/services/matching"
)

func main() {
	rand.Seed(time.Now().UnixNano())
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	runtime.GOMAXPROCS(runtime.NumCPU())

	matchEngine := matching.NewOrderBook()

	// Work Queues
	rabbitmqCh := db.RabbitmqChannel()
	rabbitmqQ := db.DeclareMatchingWorkQueue()

	// TODO prefetch
	err := rabbitmqCh.Qos(
		1,     // prefetch count
		0,     // prefetch size
		false, // global
	)
	if err != nil {
		panic(err)
	}

	deliveryChan, err := rabbitmqCh.Consume(
		rabbitmqQ.Name, // queue
		"",             // consumer
		false,          // auto-ack
		false,          // exclusive
		false,          // no-local
		false,          // no-wait
		nil,            // args
	)
	if err != nil {
		panic(err)
	}

	for delivery := range deliveryChan {
		log.Printf("Received a message: %s", delivery.Body)
		var event services.Event
		if err := json.Unmarshal(delivery.Body, &event); err != nil {
			panic(err)
		}

		switch event.Name {
		case "create_order":
			var order models.Order
			err = json.Unmarshal(event.Data, &order)
			if err != nil {
				panic(err)
			}

			log.Println("===========交易前==========")
			log.Println(matchEngine)
			// backup order book depth to redis
			obJSON, err := matchEngine.MarshalJSON()
			if err != nil {
				panic(err)
			}
			db.Redis().Set("matching_order_book", string(obJSON), 0)
			log.Println("=====================")

			side := matching.Str2Side(order.Side)
			if order.OrderType == "limit" {
				done, partial, partialQty, err := matchEngine.ProcessLimitOrder(side, order.StrID(), order.Volume, order.Price)
				if err != nil {
					panic(err)
				}
				log.Println(done, partial, partialQty)
				models.Transaction(&order, done)
			} else if order.OrderType == "market" {
				done, partial, partialQty, left, err := matchEngine.ProcessMarketOrder(side, order.Volume)
				if err != nil {
					panic(err)
				}
				log.Println(done, partial, partialQty, left)
				models.Transaction(&order, done)
			}

			log.Println("=====================")
			log.Println(matchEngine)
			log.Println("===========交易后==========")
		case "update_order":
			var order models.Order
			err = json.Unmarshal(event.Data, &order)
			if err != nil {
				panic(err)
			}
			log.Println(order)
		case "cancel_order":
			// TODO
		default:
			fmt.Printf("Default")
		}

		delivery.Ack(false)
	}
}
