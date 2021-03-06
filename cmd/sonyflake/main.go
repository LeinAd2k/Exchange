package main

import (
	"flag"
	"math/rand"
	"net/http"
	"runtime"
	"time"

	"github.com/FlowerWrong/exchange/config"
	"github.com/FlowerWrong/exchange/log"
	"github.com/gin-gonic/gin"
	"github.com/sony/sonyflake"
	"github.com/spf13/viper"
)

// @doc https://chai2010.cn/advanced-go-programming-book/ch6-cloud/ch6-01-dist-id.html
var sf *sonyflake.Sonyflake

func init() {
	var st sonyflake.Settings
	sf = sonyflake.NewSonyflake(st)
	if sf == nil {
		panic("sonyflake not created")
	}
}

// curl 127.0.0.1:8090
func main() {
	rand.Seed(time.Now().UnixNano())
	runtime.GOMAXPROCS(runtime.NumCPU())

	configFile := flag.String("config", "./config/settings.yml", "config file path")
	flag.Parse()
	err := config.Setup(*configFile)
	if err != nil {
		panic(err)
	}
	log.Println("Server launch in", config.AppEnv)

	router := gin.Default()
	router.GET("/", func(c *gin.Context) {
		id, err := sf.NextID()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, sonyflake.Decompose(id))
	})

	router.Run(viper.GetString("flake_url"))
}
