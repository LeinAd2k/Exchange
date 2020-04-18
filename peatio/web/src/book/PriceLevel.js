class PriceLevel {
  constructor(price, size) {
    this.price = price;
    this.size = size;
  }

  toString() {
    return this.size + "@" + this.price;
  }
}

export default PriceLevel;
