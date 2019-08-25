package main

import (
	"encoding/json"
	"flag"
	"log"
	"math/rand"
	"runtime"
	"time"

	"github.com/FlowerWrong/exchange/config"
	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/models"
	"github.com/FlowerWrong/exchange/services"
	"github.com/FlowerWrong/exchange/services/matching"
	"github.com/streadway/amqp"
)

func main() {
	rand.Seed(time.Now().UnixNano())
	log.SetFlags(log.LstdFlags | log.Lshortfile)
	runtime.GOMAXPROCS(runtime.NumCPU())

	configFile := flag.String("config", "./config/settings.yml", "config file path")
	flag.Parse()
	err := config.Setup(*configFile)
	if err != nil {
		panic(err)
	}
	log.Println("Matching engine launch in", config.AppEnv)

	orderBookManager := matching.NewOrderBookManager()
	var funds []models.Fund
	db.ORM().Find(&funds)
	for _, fund := range funds {
		orderBookManager.Add(fund.Symbol)
	}

	// reload db orders to matching engine when start
	models.LoadOrdersToMatchingEngine(orderBookManager)

	deliveryChan := initRabbitmq()
	for delivery := range deliveryChan {
		log.Printf("Received a message: %s", delivery.Body)
		var event services.Event
		if err := json.Unmarshal(delivery.Body, &event); err != nil {
			panic(err)
		}

		var order models.Order
		err = json.Unmarshal(event.Data, &order)
		if err != nil {
			panic(err)
		}
		matchEngine := orderBookManager.Get(order.Symbol)
		log.Println("=====================")
		log.Println(matchEngine)
		log.Println("===========交易前==========")

		switch event.Name {
		case "create_order":
			if matchEngine.Order(order.StrID()) != nil {
				log.Println("Duplicated order", order.StrID())
			} else {
				side := matching.Str2Side(order.Side)
				if order.OrderType == "limit" {
					done, partial, partialQty, err := matchEngine.ProcessLimitOrder(side, order.StrID(), order.Volume, order.Price)
					if err != nil {
						panic(err)
					}
					log.Println(done, partial, partialQty)
					models.Transaction(&order, done)
				} else if order.OrderType == "market" {
					if order.Side == "buy" {
						prices := matchEngine.CalculateMarketPrices(side, order.Volume)
						log.Println(prices)
					}
					done, partial, partialQty, left, err := matchEngine.ProcessMarketOrder(side, order.Volume)
					if err != nil {
						panic(err)
					}
					log.Println(done, partial, partialQty, left)
					models.Transaction(&order, done)
				}
			}
		case "cancel_order":
			if matchEngine.Order(order.StrID()) != nil {
				err = order.CancellingOrder()
				if err != nil {
					log.Println(err)
				} else {
					matchEngine.CancelOrder(order.StrID())
				}
			} else {
				log.Println("Order not found in matching engine", order.StrID())
			}
		default:
			log.Println("Unknown envent", event.Name)
		}

		// backup order book depth to redis
		err = matchEngine.Backup(order.Symbol)
		if err != nil {
			log.Println(err)
		}

		err = matchEngine.BackupDepth(order.Symbol)
		if err != nil {
			log.Println(err)
		}

		log.Println("===========交易后==========")
		log.Println(matchEngine)
		log.Println("=====================")

		err = delivery.Ack(false)
		if err != nil {
			panic(err)
		}
	}
}

func initRabbitmq() <-chan amqp.Delivery {
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
	return deliveryChan
}
