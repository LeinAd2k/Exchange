package huobi

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"

	"github.com/gorilla/websocket"
)

// https://huobiapi.github.io/docs/spot/v1/cn/#56c6c47284-2
const baseWSURL = "wss://api.huobi.pro/ws"

func Run() error {
	c, _, err := websocket.DefaultDialer.Dial(baseWSURL, nil)
	if err != nil {
		log.Fatal("dial:", err)
	}
	defer c.Close()

	sudData := []byte(`{
		"sub": "market.btcusdt.trade.detail",
		"id": "id1"
	}`)
	err = c.WriteMessage(websocket.TextMessage, sudData)
	if err != nil {
		log.Println("write:", err)
		return err
	}

	for {
		_, zipedMsg, err := c.ReadMessage()
		if err != nil {
			log.Println("read:", err)
			break
		}
		gzipR, _ := gzip.NewReader(bytes.NewReader(zipedMsg))
		msg, _ := ioutil.ReadAll(gzipR)

		var m map[string]interface{}
		err = json.Unmarshal([]byte(msg), &m)
		if err != nil {
			log.Println(err)
			break
		}
		if m["ping"] != nil {
			var pong map[string]interface{}
			pong = make(map[string]interface{})
			pong["pong"] = m["ping"]
			pongData, _ := json.Marshal(pong)
			log.Println(string(pongData))
			c.WriteMessage(websocket.TextMessage, pongData)
		} else {
			fmt.Println(m)
		}
	}

	return nil
}
