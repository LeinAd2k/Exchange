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
          <DepthChart title="Bitmex XBT" />
        </Col>
        <Col span={12}>col-12</Col>
      </Row>
    </div>
  );
}

export default App;
