import React from "react";

import { Decimal } from "decimal.js";

import { init, version, dispose } from "klinecharts";

import "./Kline.css";

class KlineChart extends React.PureComponent {
  constructor(props) {
    super(props);
    this.chart = null;
    this.state = {
      isLoading: false,
    };
    this.baseURL =
      "http://127.0.0.1:9292/k/" +
      this.props.exchange +
      "?symbol=" +
      this.props.symbol +
      "&interval=" +
      this.props.interval +
      "&limit=1000";
  }

  componentDidMount() {
    console.log("kline chart", version());
    this.chart = init("k_chart");
    const options = {
      grid: {
        display: true,
        horizontal: {
          display: true,
          size: 1,
          color: "#393939",
          style: "dash",
          dashValue: [2, 2],
        },
        vertical: {
          display: false,
          size: 1,
          color: "#393939",
          style: "dash",
          dashValue: [2, 2],
        },
      },
      candleStick: {
        bar: {
          style: "solid",
          upColor: "#26A69A",
          downColor: "#EF5350",
          noChangeColor: "#666666",
        },
        priceMark: {
          display: true,
          high: {
            display: true,
            color: "#D9D9D9",
            textMargin: 5,
            textSize: 10,
          },
          low: { display: true, color: "#D9D9D9", textMargin: 5, textSize: 10 },
          last: {
            display: true,
            upColor: "#26A69A",
            downColor: "#EF5350",
            noChangeColor: "#666666",
            line: { display: true, style: "dash", dashValue: [4, 4], size: 1 },
            text: {
              display: true,
              size: 12,
              paddingLeft: 2,
              paddingTop: 2,
              paddingRight: 2,
              paddingBottom: 2,
              color: "#FFFFFF",
            },
          },
        },
      },
      realTime: {
        timeLine: {
          color: "#1e88e5",
          size: 1,
          areaFillColor: "rgba(30, 136, 229, 0.08)",
        },
        averageLine: { display: true, color: "#F5A623", size: 1 },
      },
      technicalIndicator: {
        bar: {
          upColor: "#26A69A",
          downColor: "#EF5350",
          noChangeColor: "#666666",
        },
        line: {
          size: 1,
          colors: ["#D9D9D9", "#F5A623", "#F601FF", "#1587DD", "#1e88e5"],
        },
      },
      xAxis: {
        display: true,
        maxHeight: 50,
        minHeight: 30,
        axisLine: { display: true, color: "#888888", size: 1 },
        tickText: { display: true, color: "#D9D9D9", size: 12, margin: 3 },
        tickLine: { display: true, size: 1, length: 3, color: "#888888" },
      },
      yAxis: {
        display: true,
        maxWidth: 100,
        minWidth: 60,
        type: "normal",
        position: "right",
        axisLine: { display: true, color: "#888888", size: 1 },
        tickText: {
          position: "outside",
          display: true,
          color: "#D9D9D9",
          size: 12,
          margin: 3,
        },
        tickLine: { display: true, size: 1, length: 3, color: "#888888" },
      },
      separator: { size: 1, color: "#888888", fill: true },
      floatLayer: {
        crossHair: {
          display: true,
          horizontal: {
            display: true,
            line: {
              display: true,
              style: "dash",
              dashValue: [4, 2],
              size: 1,
              color: "#888888",
            },
            text: {
              display: true,
              color: "#D9D9D9",
              size: 12,
              paddingLeft: 2,
              paddingRight: 2,
              paddingTop: 2,
              paddingBottom: 2,
              borderSize: 1,
              borderColor: "#505050",
              backgroundColor: "#505050",
            },
          },
          vertical: {
            display: true,
            line: {
              display: true,
              style: "dash",
              dashValue: [4, 2],
              size: 1,
              color: "#888888",
            },
            text: {
              display: true,
              color: "#D9D9D9",
              size: 12,
              paddingLeft: 2,
              paddingRight: 2,
              paddingTop: 2,
              paddingBottom: 2,
              borderSize: 1,
              borderColor: "#505050",
              backgroundColor: "#505050",
            },
          },
        },
        prompt: {
          displayRule: "always",
          candleStick: {
            showType: "standard",
            labels: ["时间", "开", "收", "高", "低", "成交量"],
            values: null,
            rect: {
              paddingLeft: 0,
              paddingRight: 0,
              paddingTop: 0,
              paddingBottom: 6,
              left: 8,
              top: 8,
              right: 8,
              borderRadius: 4,
              borderSize: 1,
              borderColor: "#3f4254",
              fillColor: "rgba(17, 17, 17, .3)",
            },
            text: {
              size: 12,
              color: "#D9D9D9",
              marginLeft: 8,
              marginTop: 6,
              marginRight: 8,
              marginBottom: 0,
            },
          },
          technicalIndicator: {
            text: {
              size: 12,
              color: "#D9D9D9",
              marginTop: 6,
              marginRight: 8,
              marginBottom: 0,
              marginLeft: 8,
            },
            point: { display: true, radius: 3 },
          },
        },
      },
      graphicMark: {
        line: { color: "#1e88e5", size: 1 },
        point: {
          backgroundColor: "#1e88e5",
          borderColor: "#1e88e5",
          borderSize: 1,
          radius: 4,
          activeBackgroundColor: "#1e88e5",
          activeBorderColor: "#1e88e5",
          activeBorderSize: 1,
          activeRadius: 6,
        },
        text: {
          color: "#1e88e5",
          size: 12,
          marginLeft: 2,
          marginRight: 2,
          marginTop: 2,
          marginBottom: 6,
        },
      },
    };
    this.chart.setStyleOptions(options);
    this.chart.setCandleStickChartType("candle_stick");
    this.chart.setCandleStickTechnicalIndicatorType("MA");
    this.chart.addTechnicalIndicator("VOL");
    this.chart.addTechnicalIndicator();
    var that = this;

    // 添加新数据, more是告诉图表还有没有更多历史数据
    fetch(this.baseURL)
      .then((res) => res.json())
      .catch((error) => console.error("Error:", error))
      .then(function (myJson) {
        if (Array.isArray(myJson)) {
          const dataList = [];
          myJson.forEach(function (element) {
            // timestamp, open, close, high, low, volume
            const kLineModel = {
              timestamp: element[0],
              open: new Decimal(element[1]).toNumber(),
              close: new Decimal(element[2]).toNumber(),
              high: new Decimal(element[3]).toNumber(),
              low: new Decimal(element[4]).toNumber(),
              volume: new Decimal(element[5]).toNumber(),
            };
            dataList.push(kLineModel);
          });
          that.chart.applyNewData(dataList, true);
        }
      });

    // 设置加载更多回调函数
    this.chart.loadMore(() => {
      this.setState({ isLoading: true });
      const firstData = this.chart.getDataList()[0];
      const that = this;

      fetch(this.baseURL + "&end_time=" + (firstData.timestamp - 60000))
        .then((res) => res.json())
        .catch((error) => console.error("Error:", error))
        .then(function (myJson) {
          if (Array.isArray(myJson)) {
            const dataList = [];
            myJson.forEach(function (element) {
              const kLineModel = {
                timestamp: element[0],
                open: new Decimal(element[1]).toNumber(),
                close: new Decimal(element[2]).toNumber(),
                high: new Decimal(element[3]).toNumber(),
                low: new Decimal(element[4]).toNumber(),
                volume: new Decimal(element[5]).toNumber(),
              };
              dataList.push(kLineModel);
            });
            that.chart.applyMoreData(dataList, true);
          }
        });
    });

    this.addData();
  }

  componentWillUnmount() {
    dispose(this.chart);
  }

  addData() {
    setTimeout(() => {
      const dataList = this.chart.getDataList();
      const lastData = dataList[dataList.length - 1];
      const newData = { ...lastData };
      const that = this;

      fetch(this.baseURL + "&start_time=" + newData.timestamp)
        .then((res) => res.json())
        .catch((error) => console.error("Error:", error))
        .then(function (myJson) {
          if (Array.isArray(myJson)) {
            myJson.forEach(function (element) {
              const kLineModel = {
                timestamp: element[0],
                open: new Decimal(element[1]).toNumber(),
                close: new Decimal(element[2]).toNumber(),
                high: new Decimal(element[3]).toNumber(),
                low: new Decimal(element[4]).toNumber(),
                volume: new Decimal(element[5]).toNumber(),
              };
              that.chart.updateData(kLineModel);
            });
          }
        });
      this.addData();
    }, 15000);
  }

  render() {
    return (
      <div className="kline-chart-container">
        <div id="k_chart" className="kline-chart"></div>
      </div>
    );
  }
}

export default KlineChart;
