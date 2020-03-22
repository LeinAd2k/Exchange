import React from 'react';
import logo from './logo.svg';
import './App.css';

import DepthChart from './components/Depth.jsx'

// Load Highcharts modules
// require('highcharts/indicators/indicators')(Highcharts)
// require('highcharts/indicators/pivot-points')(Highcharts)
// require('highcharts/indicators/macd')(Highcharts)

function App() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <DepthChart title={"Order Book Depth"} />
      </header>
    </div>
  );
}

export default App;
