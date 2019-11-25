package binance

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/gorilla/websocket"
)

// https://binance-docs.github.io/apidocs/spot/cn/#2b149598d9
const baseWSURL = "wss://stream.binance.com:9443/ws/btcusdt@trade"

func Run() error {
	c, _, err := websocket.DefaultDialer.Dial(baseWSURL, nil)
	if err != nil {
		log.Fatal("dial:", err)
	}
	defer c.Close()

	for {
		_, msg, err := c.ReadMessage()
		if err != nil {
			log.Println("read:", err)
			break
		}

		var m map[string]interface{}
		err = json.Unmarshal(msg, &m)
		if err != nil {
			log.Println(err)
			break
		}
		fmt.Println(m)
	}

	return nil
}
