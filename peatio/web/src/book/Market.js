import OrderBook from "./OrderBook";
import UpdateEvent from "./UpdateEvent";

class Market {
  constructor(slice = 0) {
    this._books = new Map();

    this.number = Math.random();
    this.onupdate = undefined;
    this.slice = slice;
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

    let askTree = book._asks;
    let bidTree = book._bids;
    asks.forEach((element) => {
      askTree.insert(element[0], element[1]);
    });
    bids.forEach((element) => {
      bidTree.insert(element[0], element[1]);
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
  const tree = side === "B" ? book._bids : book._asks;

  const node = tree.findNode(price);
  if (node) {
    if (size > 0) {
      tree.update(price, size);
    } else {
      tree.remove(price);
    }
  } else {
    if (size > 0) {
      tree.insert(price, size);
    } else {
      // console.log("delete", price, "without node");
    }
  }
}

function onupdate(market, book, initFlag) {
  if (market.onupdate)
    if (market.slice === 0) {
      market.onupdate(new UpdateEvent(book.asks(), book.bids(), initFlag));
    } else {
      market.onupdate(
        new UpdateEvent(
          book.asks().slice(0, market.slice),
          book.bids().slice(0, market.slice),
          initFlag
        )
      );
    }
}
