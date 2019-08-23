package actions

import (
	"net/http"

	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/models"
	"github.com/gin-gonic/gin"
)

// AccountIndex ...
func AccountIndex(c *gin.Context) {
	currentUserI, exists := c.Get("currentUser")
	if exists == false {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "current user not found"})
		return
	}
	currentUser := currentUserI.(models.User)

	var accounts []models.Account
	db.ORM().Where("user_id = ?", currentUser.ID).Find(&accounts)
	c.JSON(http.StatusOK, accounts)
}

// AccountShow ...
func AccountShow(c *gin.Context) {
	currency := c.Param("currency")
	c.JSON(http.StatusOK, gin.H{
		"status": currency,
	})
}
