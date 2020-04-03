import React, { useState, useCallback, useEffect } from "react";
import useWebSocket, { ReadyState } from "react-use-websocket";

import { Button } from "antd";

import { Decimal } from "decimal.js";
import Market from "../book/Market";

import HighchartsReact from "highcharts-react-official";
import Highcharts from "highcharts";

const market = new Market();

function DepthChart(props) {
  const [socketUrl] = useState("ws://127.0.0.1:6389");
  const [sendMessage, lastMessage, readyState] = useWebSocket(socketUrl);
  const [chartOptions, setChartOptions] = useState({
    chart: {
      type: "area",
      zoomType: "xy"
    },
    title: {
      text: props.title
    },
    xAxis: {
      minPadding: 0,
      maxPadding: 0,
      plotLines: [
        {
          color: "#888",
          value: 1,
          width: 1,
          label: {
            text: "市价",
            rotation: 90
          }
        }
      ],
      title: {
        text: "价格"
      }
    },
    yAxis: [
      {
        lineWidth: 1,
        gridLineWidth: 1,
        title: null,
        tickWidth: 1,
        tickLength: 5,
        tickPosition: "inside",
        labels: {
          align: "left",
          x: 8
        }
      },
      {
        opposite: true,
        linkedTo: 0,
        lineWidth: 1,
        gridLineWidth: 0,
        title: null,
        tickWidth: 1,
        tickLength: 5,
        tickPosition: "inside",
        labels: {
          align: "right",
          x: -8
        }
      }
    ],
    legend: {
      enabled: false
    },
    plotOptions: {
      area: {
        fillOpacity: 0.2,
        lineWidth: 1,
        step: "center"
      }
    },
    tooltip: {
      headerFormat:
        '<span style="color:{series.color}">\u25CF</span> Price: <b>{point.key}</b><br/>',
      pointFormatter: function() {
        return (
          '<span style="color: ' +
          this.series.color +
          '">\u25CF</span> ' +
          this.series.name +
          ": <b>" +
          this.y +
          "</b><br/>."
        );
      },
      valueDecimals: 2
    },
    series: [
      {
        name: "Bids",
        data: [],
        color: "#03a7a8"
      },
      {
        name: "Asks",
        data: [],
        color: "#fc5857"
      }
    ]
  });

  const subData = {
    cmd: "sub",
    payload: {
      name: "bitmex_XBTUSD"
    }
  };
  const handleClickSendMessage = useCallback(
    () => sendMessage(JSON.stringify(subData)),
    [sendMessage, subData]
  );

  const instrument = "bitmex_XBTUSD";
  let updateCounter = 0;
  market.open(instrument);
  market.onupdate = function(event) {
    if (event.initFlag) {
      console.log("Init render bids", event.bids.length);
      console.log("Init render asks", event.asks.length);
    }
    if (event.initFlag || updateCounter > 7) {
      const bids = event.bids;
      const asks = event.asks;

      setChartOptions({
        xAxis: {
          minPadding: 0,
          maxPadding: 0,
          plotLines: [
            {
              color: "#888",
              value: asks[0][0],
              width: 1,
              label: {
                text: "市价",
                rotation: 90
              }
            }
          ],
          title: {
            text: "价格"
          }
        },
        series: [
          {
            name: "Bids",
            data: bids,
            color: "#03a7a8"
          },
          {
            name: "Asks",
            data: asks,
            color: "#fc5857"
          }
        ]
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
          data.asks.map(function(price_vol) {
            return [
              new Decimal(price_vol[0]).toNumber(),
              new Decimal(price_vol[1]).toNumber()
            ];
          }),
          data.bids.map(function(price_vol) {
            return [
              new Decimal(price_vol[0]).toNumber(),
              new Decimal(price_vol[1]).toNumber()
            ];
          })
        );
      } else if (data.cmd === "update") {
        data.asks.forEach(function(price_vol) {
          market.update(
            instrument,
            "S",
            new Decimal(price_vol[0]).toNumber(),
            new Decimal(price_vol[1]).toNumber()
          );
        });

        data.bids.forEach(function(price_vol) {
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
    <div>
      <Button
        type="primary"
        onClick={handleClickSendMessage}
        disabled={readyState !== ReadyState.OPEN}
      >
        Click Me to subscribe {props.title}
      </Button>
      <HighchartsReact
        highcharts={Highcharts}
        constructorType={"chart"}
        options={chartOptions}
      />
    </div>
  );
}

export default DepthChart;
