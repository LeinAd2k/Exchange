package main

import (
	"flag"
	"log"

	"github.com/FlowerWrong/exchange/actions"
	"github.com/FlowerWrong/exchange/config"
	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/middlewares"
	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
	"gopkg.in/resty.v1"
)

func main() {
	resty.SetDebug(false)
	resty.SetRESTMode()
	resty.SetHeader("Accept", "application/json")

	configFile := flag.String("config", "./config/settings.yml", "config file path")
	flag.Parse()
	err := config.Setup(*configFile)
	if err != nil {
		panic(err)
	}
	log.Println("Server launch in", config.AppEnv)

	router := gin.Default()
	router.Use(middlewares.RateLimit())

	router.GET("/ping", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "pong",
		})
	})

	v1 := router.Group("/api/v1")
	{
		v1.POST("/login", actions.Login)
	}

	authGroup := router.Group("/api/v1", middlewares.JWTAuth())
	{
		authGroup.GET("/orders", actions.OrderIndex)
		authGroup.POST("/orders", actions.OrderCreate)
		authGroup.DELETE("/orders/:id", actions.OrderCancel)

		authGroup.GET("/accounts", actions.AccountIndex)

		authGroup.GET("/order_books", actions.OrderBookIndex)
	}

	// rabbitmq
	db.RabbitmqChannel()
	db.DeclareMatchingWorkQueue()

	router.Run(viper.GetString("api_url"))
}
