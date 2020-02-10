package binance

import (
	"encoding/json"

	"gopkg.in/resty.v1"
)

const baseURL = "https://api.binance.com/api/v3"

// Ping ...
func Ping() (map[string]interface{}, error) {
	resp, err := resty.R().Get(baseURL + "/ping")
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

// ServerTimestamp ...
func ServerTimestamp() (map[string]interface{}, error) {
	resp, err := resty.R().Get(baseURL + "/time")
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
