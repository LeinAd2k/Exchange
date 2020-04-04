import React, { useState, useCallback, useEffect } from "react";
import useWebSocket, { ReadyState } from "react-use-websocket";

import { Decimal } from "decimal.js";
import Market from "../book/Market";

import OrderBook from "../tradingUI/OrderBook";

import "./OrderBookUI.css";

const market = new Market(10);

function OrderBookUI(props) {
  const [socketUrl] = useState("ws://127.0.0.1:6389");
  const [sendMessage, lastMessage, readyState] = useWebSocket(socketUrl);
  const [book, setBook] = useState({
    asks: [],
    bids: [],
  });

  const subData = {
    cmd: "sub",
    payload: {
      name: "bitmex_XBTUSD",
    },
  };
  const handleClickSendMessage = useCallback(
    () => sendMessage(JSON.stringify(subData)),
    [sendMessage, subData]
  );

  const instrument = "bitmex_XBTUSD";
  let updateCounter = 0;
  market.open(instrument);
  market.onupdate = function (event) {
    if (event.initFlag) {
      console.log("Init render bids", event.bids.length);
      console.log("Init render asks", event.asks.length);
    }
    if (event.initFlag || updateCounter > 10) {
      const bids = event.bids;
      const asks = event.asks;

      setBook({
        asks: asks,
        bids: bids,
      });
      updateCounter = 0;
    } else {
      updateCounter += 1;
    }
  };

  useEffect(() => {
    if (lastMessage !== null) {
      const data = JSON.parse(lastMessage.data);

      if (data.cmd === "partial") {
        market.initOrderBook(
          instrument,
          data.asks.map(function (price_vol) {
            return [
              new Decimal(price_vol[0]).toNumber(),
              new Decimal(price_vol[1]).toNumber(),
            ];
          }),
          data.bids.map(function (price_vol) {
            return [
              new Decimal(price_vol[0]).toNumber(),
              new Decimal(price_vol[1]).toNumber(),
            ];
          })
        );
      } else if (data.cmd === "update") {
        data.asks.forEach(function (price_vol) {
          market.update(
            instrument,
            "S",
            new Decimal(price_vol[0]).toNumber(),
            new Decimal(price_vol[1]).toNumber()
          );
        });

        data.bids.forEach(function (price_vol) {
          market.update(
            instrument,
            "B",
            new Decimal(price_vol[0]).toNumber(),
            new Decimal(price_vol[1]).toNumber()
          );
        });
      }
    }
  }, [lastMessage]);

  return (
    <div className="order_book_ui">
      <button
        onClick={handleClickSendMessage}
        disabled={readyState !== ReadyState.OPEN}
      >
        Click Me to subscribe data
      </button>
      <OrderBook
        asks={book.asks}
        bids={book.bids}
        getPrice={(entry) => entry[0]}
        getSize={(entry) => entry[1]}
        headerText={props.title}
        showSizeBar={true}
      />
      {/* <OrderBook asks={book.asks} bids={book.bids} /> */}
    </div>
  );
}

export default OrderBookUI;
