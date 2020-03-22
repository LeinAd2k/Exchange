import OrderBook from "./OrderBook";
import PriceLevel from "./PriceLevel";
import UpdateEvent from "./UpdateEvent";

class Market {
  constructor() {
    this._books = new Map();

    this.number = Math.random();
    this.onupdate = undefined;
  }

  open(instrument) {
    let book = this._books.get(instrument);
    if (!book) {
      book = new OrderBook(instrument);

      this._books.set(instrument, book);
    }

    return book;
  }

  initOrderBook(instrument, asks, bids) {
    const book = this._books.get(instrument);
    if (!book) return;

    let askLevels = book._asks;
    let bidLevels = book._bids;
    asks.forEach(element => {
      askLevels.add(new PriceLevel(element[0], element[1]));
    });
    bids.forEach(element => {
      bidLevels.add(new PriceLevel(element[0], element[1]));
    });
    console.log("order book inited");
    onupdate(this, book, true);
  }

  update(instrument, side, price, size) {
    const book = this._books.get(instrument);
    if (!book) return;

    update(book, side, price, size);
    onupdate(this, book, false);
  }
}

export default Market;

function update(book, side, price, size) {
  const levels = side === "B" ? book._bids : book._asks;

  const node = levels.find(new PriceLevel(price));
  if (node) {
    if (size > 0) {
      node.value.size = size;
    } else {
      levels.delete(new PriceLevel(price));
    }
  } else {
    levels.add(new PriceLevel(price, size));
  }
}

function onupdate(market, book, initFlag) {
  if (market.onupdate)
    market.onupdate(new UpdateEvent(book.asks(), book.bids(), initFlag));
}
