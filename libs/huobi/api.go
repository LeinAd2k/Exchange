package huobi

import (
	"encoding/json"
	"gopkg.in/resty.v1"
)

const BaseURL = "https://api.huobi.pro"

func GetTrade(symbol string) (map[string]interface{}, error) {
	resp, err := resty.R().Get(BaseURL + "/market/trade?symbol=" + symbol)
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
