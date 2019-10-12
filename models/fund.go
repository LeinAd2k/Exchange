package models

// Fund ...
type Fund struct {
	CurrencyBaseModel
	Name          string
	BaseCurrency  Currency `gorm:"foreignkey:Base"`
	Base          string
	QuoteCurrency Currency `gorm:"foreignkey:Quote"`
	Quote         string
}
