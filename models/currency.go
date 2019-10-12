package models

// Currency @doc https://github.com/rubykube/peatio/blob/master/app/models/currency.rb
type Currency struct {
	CurrencyBaseModel
	Precision int32 `json:"precision"`
}
