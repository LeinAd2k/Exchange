package actions

import (
	"encoding/json"
	"net/http"

	"github.com/FlowerWrong/exchange/actions/forms"
	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/dtos"
	"github.com/FlowerWrong/exchange/models"
	"github.com/FlowerWrong/exchange/services"
	"github.com/FlowerWrong/exchange/services/matching"
	"github.com/FlowerWrong/exchange/utils"
	"github.com/devfeel/mapper"
	"github.com/gin-gonic/gin"
	"github.com/shopspring/decimal"
)

// OrderIndex ...
func OrderIndex(c *gin.Context) {
	currentUserI, exists := c.Get("currentUser")
	if exists == false {
		c.JSON(http.StatusUnauthorized, gin.H{"error": models.ErrUserNotFound.Error()})
		return
	}
	currentUser := currentUserI.(models.User)

	page, _ := utils.Str2Int64(c.DefaultQuery("page", "1"))
	per, _ := utils.Str2Int64(c.DefaultQuery("per", "10"))

	var orders []models.Order
	db.ORM().Where("user_id = ?", currentUser.ID).Limit(per).Offset((page - 1) * per).Find(&orders)

	// response
	var orderDTOs []dtos.OrderDTO
	for _, order := range orders {
		orderDTO := &dtos.OrderDTO{}
		err := mapper.AutoMapper(&order, orderDTO)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		orderDTOs = append(orderDTOs, *orderDTO)
	}
	c.JSON(http.StatusOK, orderDTOs)
}

// OrderCreate ...
func OrderCreate(c *gin.Context) {
	var err error
	var orderForm forms.OrderForm
	if err = c.ShouldBindJSON(&orderForm); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	order := &models.Order{}
	err = mapper.AutoMapper(&orderForm, order)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	currentUserI, exists := c.Get("currentUser")
	if exists == false {
		c.JSON(http.StatusUnauthorized, gin.H{"error": models.ErrUserNotFound.Error()})
		return
	}
	currentUser := currentUserI.(models.User)
	order.UserID = currentUser.ID

	fund := &models.Fund{}
	db.ORM().Where("id = ?", orderForm.Symbol).First(&fund)
	order.FundID = fund.ID
	order.OriginVolume = order.Volume

	// 检验对手单够不够
	if order.OrderType == "market" {
		depthJSON, err := db.Redis().Get(db.DepthKey(order.FundID)).Result()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		var depth matching.Depth
		err = json.Unmarshal([]byte(depthJSON), &depth)
		if err != nil {
			panic(err)
		}
		if order.Side == "buy" {
			if len(depth.Asks) == 0 {
				c.JSON(http.StatusBadRequest, gin.H{"error": models.ErrWithoutEnoughOtherSideOrder.Error()})
				return
			}
		} else {
			if len(depth.Bids) == 0 {
				c.JSON(http.StatusBadRequest, gin.H{"error": models.ErrWithoutEnoughOtherSideOrder.Error()})
				return
			}
		}

		order.Price = decimal.NewFromFloat(0)
	}

	// 校验钱够不够
	account := &models.Account{}
	var locked decimal.Decimal
	if order.Side == "buy" {
		// BTC_USD 为例，购买动作即用USD买BTC，锁定账户的USD
		if order.OrderType == "market" {
			locked = order.Volume // USD
		} else {
			locked = order.Volume.Mul(order.Price) // 单价 * 数量
		}
		models.FindAccountByUserIDAndCurrencyID(db.ORM(), account, order.UserID, fund.Quote)
		if account.Balance.Sub(locked).Sign() < 0 {
			c.JSON(http.StatusInternalServerError, gin.H{"error": models.ErrWithoutEnoughMoney.Error()})
			return
		}
	} else {
		models.FindAccountByUserIDAndCurrencyID(db.ORM(), account, order.UserID, fund.Base)
		locked = order.Volume
		if account.Balance.Sub(locked).Sign() < 0 {
			c.JSON(http.StatusInternalServerError, gin.H{"error": models.ErrWithoutEnoughMoney.Error()})
			return
		}
	}

	// 相同品种，相同价格得单不合并

	now := utils.UTCNow()
	order.CreatedAt = now
	order.UpdatedAt = now

	order.ID, err = utils.NextID()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	order.State = models.Wait
	err = order.CreateOrder(account, locked)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// 发送给queue
	data := services.OrderEvent(order, "create_order")
	err = db.PublishToMatching(data)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// response
	orderDTO := &dtos.OrderDTO{}
	err = mapper.AutoMapper(order, orderDTO)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, orderDTO)
}

// OrderCancel ...
func OrderCancel(c *gin.Context) {
	id := c.Param("id")

	currentUserI, exists := c.Get("currentUser")
	if exists == false {
		c.JSON(http.StatusUnauthorized, gin.H{"error": models.ErrUserNotFound.Error()})
		return
	}
	currentUser := currentUserI.(models.User)

	// do not update here
	var order models.Order
	db.ORM().Where("id = ? and user_id = ?", id, currentUser.ID).First(&order)
	if order.State != models.Wait {
		c.JSON(http.StatusBadRequest, gin.H{"error": models.ErrCancelNoneWaitOrder.Error()})
		return
	}

	if order.OrderType == "market" {
		c.JSON(http.StatusBadRequest, gin.H{"error": models.ErrCancelMarketOrder.Error()})
		return
	}

	orderUpdate := models.Order{State: models.Cancelling}
	db.ORM().Model(&order).Updates(orderUpdate)

	// 发送给queue
	data := services.OrderEvent(&order, "cancel_order")
	err := db.PublishToMatching(data)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	// response
	orderDTO := &dtos.OrderDTO{}
	err = mapper.AutoMapper(&order, orderDTO)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	c.JSON(http.StatusOK, orderDTO)
}
