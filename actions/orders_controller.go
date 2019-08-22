package actions

import (
	"encoding/json"
	"net/http"
	"time"

	"github.com/FlowerWrong/exchange/actions/forms"
	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/dtos"
	"github.com/FlowerWrong/exchange/models"
	"github.com/FlowerWrong/exchange/services"
	"github.com/FlowerWrong/exchange/utils"
	"github.com/devfeel/mapper"
	"github.com/gin-gonic/gin"
	"github.com/spf13/viper"
	"github.com/streadway/amqp"
)

// OrderIndex ...
func OrderIndex(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status": "success",
	})
}

// OrderCreate ...
func OrderCreate(c *gin.Context) {
	var orderForm forms.OrderForm
	if err := c.ShouldBindJSON(&orderForm); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	order := &models.Order{}
	mapper.AutoMapper(&orderForm, order)

	currentUserI, exists := c.Get("currentUser")
	if exists == false {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "current user not found"})
		return
	}
	currentUser := currentUserI.(*models.User)
	order.UserID = currentUser.ID

	account := &models.Account{}
	fund := models.Fund{}
	db.ORM().First(&fund, order.FundID)
	order.FundID = fund.ID
	if order.OrderType == "market" {
		order.Price = models.CurrentPrice(order.Symbol) // 现价 TOOD 如果库里没有订单怎么办?
	}
	if order.Side == "buy" {
		// BTC_USD 为例，购买动作即用USD买BTC，锁定账户的USD
		turnover := order.Volume.Mul(order.Price) // 单价 * 数量
		models.FindAccountByUserIDAndCurrencyID(db.ORM(), account, order.UserID, fund.RightCurrencyID)
		if account.Balance.Sub(turnover).Sign() < 0 {
			c.JSON(http.StatusInternalServerError, gin.H{"error": models.ErrWithoutEnoughMoney})
			return
		}
	} else {
		models.FindAccountByUserIDAndCurrencyID(db.ORM(), account, order.UserID, fund.LeftCurrencyID)
		if account.Balance.Sub(order.Volume).Sign() < 0 {
			c.JSON(http.StatusInternalServerError, gin.H{"error": models.ErrWithoutEnoughMoney})
			return
		}
	}

	// TODO 检验对手单够不够
	// TODO 校验钱够不够

	// 相同品种，相同价格得单不合并

	order.CreatedAt = time.Now()
	order.UpdatedAt = time.Now()

	id, err := utils.NextID()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	order.ID = id

	// 发送给queue
	b, err := json.Marshal(order)
	if err != nil {
		panic(err)
	}
	raw := json.RawMessage(b)
	event := &services.Event{Name: "create_order", Data: raw}
	data, err := json.Marshal(event)
	if err != nil {
		panic(err)
	}

	db.RabbitmqChannel().Publish(
		"", // exchange
		viper.GetString("matching_work_queue_name"), // routing key
		false, // mandatory
		false, // immediate
		amqp.Publishing{
			DeliveryMode: amqp.Persistent,
			ContentType:  "text/plain",
			Body:         data,
		})

	orderDTO := &dtos.OrderDTO{}
	mapper.AutoMapper(order, orderDTO)
	c.JSON(http.StatusOK, orderDTO)
}

// OrderUpdate ...
func OrderUpdate(c *gin.Context) {
	id := c.Param("id")
	var orderUpdate models.Order
	if err := c.ShouldBindJSON(&orderUpdate); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// do not update here
	var order models.Order
	db.ORM().Where("id = ? and volume > 0", id).First(&order)
	order.Volume = orderUpdate.Volume
	order.Price = orderUpdate.Price
	db.ORM().Save(&order)

	// 发送给queue

	c.JSON(http.StatusOK, order)
}

// OrderCancel ...
func OrderCancel(c *gin.Context) {
	id := c.Param("id")
	// do not update here
	var order models.Order
	db.ORM().Where("id = ?", id).First(&order).Delete(&order)

	// 发送给queue

	c.JSON(http.StatusOK, utils.APIRes{Code: 0, Message: "ok"})
}
