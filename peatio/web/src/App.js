import React from "react";
import { Button } from "antd";

import logo from "./logo.svg";
import "./App.css";

import DepthChart from "./components/Depth.jsx";

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <Button type="primary">Button</Button>
        <DepthChart title={"Order Book Depth"} />
      </header>
    </div>
  );
}

export default App;
