import React from "react";

import logo from "./logo.svg";
import "./App.css";

// import DepthChart from "./components/Depth.jsx";
import OrderBookUI from "./components/OrderBookUI.jsx";

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <OrderBookUI title={"Order Book Depth"} />
      </header>
    </div>
  );
}

export default App;
