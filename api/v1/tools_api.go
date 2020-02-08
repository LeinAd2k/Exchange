package v1

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

// Timestamp ...
func Timestamp(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"server_timestamp": time.Now().Nanosecond(),
	})
}
