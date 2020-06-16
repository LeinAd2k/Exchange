import React from "react";
import { Row, Col } from "antd";

import "./App.css";

import DepthChart from "./components/Depth.jsx";
// import KlineChart from "./components/Kline.jsx";
import TvChart from "./components/Tv.jsx";
import OrderBookUI from "./components/OrderBookUI";

function App() {
  return (
    <div className="App">
      <Row>
        <Col span={24}>
          <header className="App-header"></header>
        </Col>
      </Row>
      <Row>
        <Col span={12}>
          <DepthChart title="Bitmex XBTUSD" instrument="bitmex_XBTUSD" />
        </Col>
        <Col span={12}>
          <DepthChart title="Binance BTCUSDT" instrument="binance_BTCUSDT" />
        </Col>
      </Row>
      {/* <Row>
        <Col span={8}>
          <OrderBookUI
            title="Bitmex order book"
            exchange="bitmex"
            symbol="XBTUSD"
          />
        </Col>
        <Col span={8}>
          <OrderBookUI
            title="Bitmex order book"
            exchange="bitmex"
            symbol="XBTUSD"
          />
        </Col>
        <Col span={8}>
          <OrderBookUI
            title="Bitmex order book"
            exchange="bitmex"
            symbol="XBTUSD"
          />
        </Col>
      </Row> */}
      <Row>
        <Col span={24}>
          <TvChart />
        </Col>
      </Row>
      {/* <Row>
        <Col span={24}>
          <KlineChart exchange="binance" symbol="BTCUSDT" interval="1d" />
        </Col>
      </Row> */}
    </div>
  );
}

export default App;
