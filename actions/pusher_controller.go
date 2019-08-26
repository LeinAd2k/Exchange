package actions

import (
	"bytes"
	"io/ioutil"
	"net/http"

	"github.com/FlowerWrong/exchange/db"
	"github.com/FlowerWrong/exchange/log"
	"github.com/FlowerWrong/exchange/utils"
	pusherServer "github.com/FlowerWrong/pusher"
	"github.com/gin-gonic/gin"
	"github.com/pusher/pusher-http-go"
)

type pusherAuth struct {
	SocketID    string `form:"socket_id" json:"socket_id" xml:"socket_id" binding:"required"`
	ChannelName string `form:"channel_name" json:"channel_name" xml:"channel_name" binding:"required"`
}

// PusherAuth ...
func PusherAuth(c *gin.Context) {
	// Read the Body content
	var bodyBytes []byte
	if c.Request.Body != nil {
		bodyBytes, _ = ioutil.ReadAll(c.Request.Body)
	}
	c.Request.Body = ioutil.NopCloser(bytes.NewBuffer(bodyBytes))

	var err error
	var auth pusherAuth
	if err = c.ShouldBind(&auth); err != nil {
		log.Println(err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}
	log.Println(auth.SocketID, auth.ChannelName)

	client := db.Pusher()

	id, err := utils.NextID()
	if err != nil {
		panic(err)
	}
	if pusherServer.IsPresenceChannel(auth.ChannelName) {
		presenceData := pusher.MemberData{
			UserID: utils.Uint642Str(id),
			UserInfo: map[string]string{
				"twitter": "pusher",
			},
		}
		response, err := client.AuthenticatePresenceChannel(bodyBytes, presenceData)
		if err != nil {
			panic(err)
		}
		c.Data(http.StatusOK, "application/json", response)
	} else if pusherServer.IsPrivateChannel(auth.ChannelName) {
		response, err := client.AuthenticatePrivateChannel(bodyBytes)
		if err != nil {
			panic(err)
		}
		c.Data(http.StatusOK, "application/json", response)
	} else {
		c.JSON(http.StatusForbidden, gin.H{"error": "only private and presence channel support"})
	}
}

// PusherWebhook ...
func PusherWebhook(c *gin.Context) {
	body, _ := ioutil.ReadAll(c.Request.Body)

	client := db.Pusher()
	webhook, err := client.Webhook(c.Request.Header, body)
	log.Println(webhook)
	if err != nil {
		log.Println(err)
		c.JSON(http.StatusBadRequest, gin.H{})
		return
	}

	c.JSON(http.StatusOK, gin.H{})
}
