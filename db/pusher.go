package db

import (
	"sync"

	"github.com/pusher/pusher-http-go"
	"github.com/spf13/viper"
)

var (
	pusherClient *pusher.Client
	pusherOnce   sync.Once
)

func initPusherClient() error {
	var err error
	pusherClient, err = pusher.ClientFromURL(viper.GetString("pusher_url"))
	if err != nil {
		return err
	}
	return nil
}

// Pusher return pusher client
func Pusher() *pusher.Client {
	if pusherClient == nil {
		pusherOnce.Do(func() {
			err := initPusherClient()
			if err != nil {
				panic(err)
			}
		})
	}
	return pusherClient
}
