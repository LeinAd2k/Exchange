import SortedSet from "collections/sorted-set";

class OrderBook {
  constructor(instrument) {
    this.instrument = instrument;

    const equal = (a, b) => a.price === b.price;

    this._bids = new SortedSet([], equal, (a, b) => b.price - a.price);
    this._asks = new SortedSet([], equal, (a, b) => a.price - b.price);
  }

  bestBid() {
    const node = this._bids.findLeast();

    return node ? node.value : undefined;
  }

  bestAsk() {
    const node = this._asks.findLeast();

    return node ? node.value : undefined;
  }

  bids() {
    return this._bids
      .slice(0, 500)
      .reverse()
      .map(function(pl) {
        return [pl.price, pl.size];
      });
  }

  asks() {
    return this._asks
      .sorted()
      .slice(0, 500)
      .map(function(pl) {
        return [pl.price, pl.size];
      });
  }
}

export default OrderBook;
