package main

import (
	"encoding/json"
	"flag"
	"math/rand"
	"runtime"
	"time"

	"github.com/FlowerWrong/exchange/config"
	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/log"
	"github.com/FlowerWrong/exchange/models"
	"github.com/FlowerWrong/exchange/services"
	"github.com/FlowerWrong/exchange/services/matching"
	"github.com/streadway/amqp"
)

func main() {
	rand.Seed(time.Now().UnixNano())
	runtime.GOMAXPROCS(runtime.NumCPU())

	configFile := flag.String("config", "./config/settings.yml", "config file path")
	flag.Parse()
	err := config.Setup(*configFile)
	if err != nil {
		log.Panic(err)
	}
	log.Infoln("Matching engine launch in", config.AppEnv)

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
		log.Infof("Received a message: %s", delivery.Body)
		var event services.Event
		if err := json.Unmarshal(delivery.Body, &event); err != nil {
			log.Error(err)
			continue
		}

		var order models.Order
		err = json.Unmarshal(event.Data, &order)
		if err != nil {
			log.Error(err)
			continue
		}

		matchEngine := orderBookManager.Get(order.Symbol)
		log.Infoln(matchEngine)

		switch event.Name {
		case "create_order":
			if matchEngine.Order(order.StrID()) != nil {
				log.Errorln("Duplicated order", order.StrID())
				continue
			}

			if order.State != models.Wait {
				log.Error("Invalid order state", order.State, "of", order.ID)
				continue
			}

			side := matching.Str2Side(order.Side)
			if order.OrderType == "limit" {
				done, partial, partialQty, err := matchEngine.ProcessLimitOrder(side, order.StrID(), order.Volume, order.Price)
				if err != nil {
					log.Panic(err)
				}
				log.Infoln(done, partial, partialQty)
				models.Transaction(&order, done)
			} else if order.OrderType == "market" {
				if order.Side == "buy" {
					prices := matchEngine.CalculateMarketPrices(side, order.Volume)
					log.Infoln(prices)
				}
				done, partial, partialQty, left, err := matchEngine.ProcessMarketOrder(side, order.Volume)
				if err != nil {
					log.Panic(err)
				}
				log.Infoln(done, partial, partialQty, left)
				models.Transaction(&order, done)
			}
		case "cancel_order":
			if matchEngine.Order(order.StrID()) != nil {
				err = order.CancellingOrder()
				if err != nil {
					log.Panic(err)
				} else {
					matchEngine.CancelOrder(order.StrID())
				}
			} else {
				log.Errorln("Order not found in matching engine", order.StrID())
			}
		default:
			log.Errorln("Unknown event", event.Name)
		}

		// backup order book depth to redis
		err = matchEngine.Backup(order.Symbol)
		if err != nil {
			log.Error(err)
		}

		err = matchEngine.BackupDepth(order.Symbol)
		if err != nil {
			log.Error(err)
		}

		log.Infoln(matchEngine)

		err = delivery.Ack(false)
		if err != nil {
			log.Error(err)
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
		log.Panic(err)
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
		log.Panic(err)
	}
	return deliveryChan
}
