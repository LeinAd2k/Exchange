package actions

import (
	"net/http"
	"time"

	"github.com/FlowerWrong/exchange/actions/forms"
	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/models"
	"github.com/FlowerWrong/exchange/utils"
	"github.com/gin-gonic/gin"
)

// Login ...
func Login(c *gin.Context) {
	var login forms.LoginForm
	if err := c.ShouldBindJSON(&login); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	var user models.User
	db.ORM().Where("name = ?", login.Username).First(&user)

	err := utils.CheckPassword(user.PasswordDigest, login.Password)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "password is wrong"})
		return
	}

	token, err := utils.GenerateToken(&user)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	err = db.Redis().SetNX(utils.Uint642Str(user.ID), token, 7*24*60*60*time.Second).Err()
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"token": token})
}
