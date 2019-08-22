package actions

import (
	"net/http"

	"github.com/FlowerWrong/exchange/utils"
	"github.com/gin-gonic/gin"
)

// OrderBookIndex ...
func OrderBookIndex(c *gin.Context) {
	symbol := c.DefaultQuery("symbol", "all")

	c.JSON(http.StatusOK, utils.APIRes{Code: 0, Message: symbol})
}
