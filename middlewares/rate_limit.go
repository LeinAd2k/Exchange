package middlewares

import (
	"time"

	"github.com/FlowerWrong/exchange/db"
	"github.com/gin-gonic/gin"
	"github.com/ulule/limiter"
	mgin "github.com/ulule/limiter/drivers/middleware/gin"
	sredis "github.com/ulule/limiter/drivers/store/redis"
)

// RateLimit middleware
func RateLimit() gin.HandlerFunc {
	rate := limiter.Rate{
		Period: 1 * time.Hour,
		Limit:  65536,
	}

	store, err := sredis.NewStore(db.Redis())
	if err != nil {
		panic(err)
	}
	return mgin.NewMiddleware(limiter.New(store, rate))
}
