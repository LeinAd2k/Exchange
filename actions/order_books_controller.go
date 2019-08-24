package actions

import (
	"net/http"

	"github.com/FlowerWrong/exchange/db"
	"github.com/gin-gonic/gin"
)

// OrderBookIndex ...
func OrderBookIndex(c *gin.Context) {
	symbol := c.Query("symbol")

	data, err := db.Redis().Get(db.DepthKey(symbol)).Result()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.Data(http.StatusOK, "application/json", []byte(data))
}
