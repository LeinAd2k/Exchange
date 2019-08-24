package actions

import (
	"net/http"

	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/dtos"
	"github.com/FlowerWrong/exchange/models"
	"github.com/FlowerWrong/exchange/utils"
	"github.com/devfeel/mapper"
	"github.com/gin-gonic/gin"
)

// AccountIndex ...
func AccountIndex(c *gin.Context) {
	currentUserI, exists := c.Get("currentUser")
	if exists == false {
		c.JSON(http.StatusUnauthorized, gin.H{"error": models.ErrUserNotFound.Error()})
		return
	}
	currentUser := currentUserI.(models.User)

	page, _ := utils.Str2Int64(c.DefaultQuery("page", "1"))
	per, _ := utils.Str2Int64(c.DefaultQuery("per", "10"))

	var accounts []models.Account
	db.ORM().Where("user_id = ?", currentUser.ID).Limit(per).Offset((page - 1) * per).Find(&accounts)

	// response
	var accountDTOs []dtos.AccountDTO
	for _, account := range accounts {
		accountDTO := &dtos.AccountDTO{}
		err := mapper.AutoMapper(&account, accountDTO)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		accountDTOs = append(accountDTOs, *accountDTO)
	}
	c.JSON(http.StatusOK, accountDTOs)
}
