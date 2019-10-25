package bitmex

import (
	"encoding/json"
	"gopkg.in/resty.v1"
)

const BaseURL = "https://www.bitmex.com"

func GetInstrument(symbol string) (map[string]interface{}, error) {
	resp, err := resty.R().Get(BaseURL + "/api/v1/instrument?symbol=" + symbol + "&columns=lastPrice&count=1&reverse=true")
	if err != nil {
		return nil, err
	}
	var m map[string]interface{}
	err = json.Unmarshal([]byte(resp.Body()), &m)
	if err != nil {
		return nil, err
	}

	return m, nil
}