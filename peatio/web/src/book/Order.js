class Order {
  constructor(book, side, price, size) {
    this.book = book;

    this.side = side;
    this.price = price;

    this.remainingQuantity = size;
  }
}

export default Order;
