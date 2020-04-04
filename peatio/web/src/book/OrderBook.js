import RbTree from "red-black-tree-js";

class OrderBook {
  constructor(instrument) {
    this.instrument = instrument;

    this._asks = new RbTree();
    this._bids = new RbTree();
  }

  bids() {
    return this._bids
      .toSortedArray()
      .map(function (pl) {
        return [pl.key, pl.value];
      })
      .reverse();
  }

  asks() {
    return this._asks.toSortedArray().map(function (pl) {
      return [pl.key, pl.value];
    });
  }
}

export default OrderBook;
