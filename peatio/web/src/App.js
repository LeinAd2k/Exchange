import React from "react";
import { Row, Col } from "antd";

import "./App.css";

import DepthChart from "./components/Depth.jsx";

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
    </div>
  );
}

export default App;
