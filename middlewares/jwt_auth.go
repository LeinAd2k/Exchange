package middlewares

import (
	"net/http"
	"strings"

	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/models"
	"github.com/FlowerWrong/exchange/utils"
	"github.com/gin-gonic/gin"
)

// JWTAuth ...
func JWTAuth() gin.HandlerFunc {
	return func(c *gin.Context) {
		token := c.DefaultQuery("token", "")
		if token == "" {
			token = c.Request.Header.Get("Authorization")
			if s := strings.Split(token, " "); len(s) == 2 {
				token = s[1]
			}
		}

		claims, err := utils.ParseToken(token)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		var user models.User
		db.ORM().First(&user, claims.ID)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		val, err := db.Redis().Get(utils.Uint642Str(user.ID)).Result()
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": err.Error()})
			c.Abort()
			return
		}

		if val != token {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token"})
			c.Abort()
			return
		}

		c.Set("currentUser", user)
		c.Next()
	}
}
