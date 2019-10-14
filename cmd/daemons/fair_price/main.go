package main

import (
	"math/rand"
	"runtime"
	"time"

	"github.com/FlowerWrong/exchange/log"
)

func main() {
	rand.Seed(time.Now().UnixNano())
	runtime.GOMAXPROCS(runtime.NumCPU())

	log.Infoln("Fair price daemon started")

	baseLendingRate := 0.000300  // 基础利率
	quoteLendingRate := 0.000600 // 计价利率

	interestRate := (quoteLendingRate - baseLendingRate) / 3 // 利率
	log.Println("Interest Rate is", interestRate)

	premiumRate := 0 // 溢价率
	log.Println("Premium Rate is", premiumRate)

	fundingRate := 0 // 资金费率
	log.Println("Funding Rate is", fundingRate)
}
