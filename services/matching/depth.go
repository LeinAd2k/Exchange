package matching

// Depth contains asks and bids
type Depth struct {
	Asks []PriceLevel `json:"asks"`
	Bids []PriceLevel `json:"bids"`
}
