package huobi

import (
	"bytes"
	"compress/gzip"
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

	err = c.WriteMessage(websocket.TextMessage, []byte("{\r\n  \"sub\": \"market.btcusdt.trade.detail\",\r\n  \"id\": \"id1\"\r\n}"))
	if err != nil {
		log.Println("write:", err)
		return err
	}

	for {
		_, message, err := c.ReadMessage()
		if err != nil {
			log.Println("read:", err)
			break
		}
		rdata := bytes.NewReader(message)
		r, _ := gzip.NewReader(rdata)
		s, _ := ioutil.ReadAll(r)
		log.Printf("recv: %s", string(s))
	}

	return nil
}
