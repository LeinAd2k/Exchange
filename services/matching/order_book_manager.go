package matching

// OrderBookManager ...
type OrderBookManager struct {
	engines map[string]*OrderBook
}

// NewOrderBookManager ...
func NewOrderBookManager() *OrderBookManager {
	return &OrderBookManager{engines: make(map[string]*OrderBook)}
}

// Add engine
func (obm *OrderBookManager) Add(symbol string) *OrderBookManager {
	if obm.engines[symbol] != nil {
		return obm
	}
	obm.engines[symbol] = NewOrderBook()
	return obm
}

// Get ...
func (obm *OrderBookManager) Get(symbol string) *OrderBook {
	return obm.engines[symbol]
}
