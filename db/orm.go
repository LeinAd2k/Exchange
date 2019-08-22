package db

import (
	"sync"

	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
	"github.com/spf13/viper"
)

var (
	orm    *gorm.DB
	dbOnce sync.Once
)

func initORM() error {
	var err error
	orm, err = gorm.Open("mysql", viper.GetString("db_url"))
	if err != nil {
		return err
	}
	err = orm.DB().Ping()
	if err != nil {
		return err
	}
	orm.LogMode(true)
	return nil
}

// ORM ...
func ORM() *gorm.DB {
	if orm == nil {
		dbOnce.Do(func() {
			err := initORM()
			if err != nil {
				panic(err)
			}
		})
	}
	return orm
}
