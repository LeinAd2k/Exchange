class UpdateEvent {
  constructor(asks, bids, initFlag) {
    this.asks = asks;
    this.bids = bids;
    this.initFlag = initFlag;
  }
}

export default UpdateEvent;
