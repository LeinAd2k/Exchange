package utils

import (
	"errors"
	"time"

	"github.com/FlowerWrong/exchange/models"
	jwt "github.com/dgrijalva/jwt-go"
	"github.com/spf13/viper"
)

// doc https://godoc.org/github.com/dgrijalva/jwt-go

// CustomJWTClaims ...
type CustomJWTClaims struct {
	Username string `json:"username"`
	ID       uint64 `json:"id"`
	jwt.StandardClaims
}

// ErrInvalidToken ...
var ErrInvalidToken error = errors.New("Token is invalid")

// GenerateToken ...
func GenerateToken(user *models.User) (string, error) {
	jwtSigningKey := []byte(viper.GetString("jwt_key"))

	expirationTime := time.Now().Add(7 * 24 * time.Hour)
	claims := CustomJWTClaims{
		user.Name,
		user.ID,
		jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
			Issuer:    "exchange",
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	return token.SignedString(jwtSigningKey)
}

// ParseToken ...
func ParseToken(tokenStr string) (*CustomJWTClaims, error) {
	jwtSigningKey := []byte(viper.GetString("jwt_key"))
	token, err := jwt.ParseWithClaims(tokenStr, &CustomJWTClaims{}, func(token *jwt.Token) (interface{}, error) {
		return jwtSigningKey, nil
	})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*CustomJWTClaims); ok && token.Valid {
		return claims, nil
	}
	return nil, ErrInvalidToken
}
