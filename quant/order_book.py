import websocket

try:
    import thread
except ImportError:
    import _thread as thread
import time
import json
import random

# import numpy as np
import matplotlib.pyplot as plt

from bintrees import RBTree
from decimal import *

getcontext().prec = 32

ask_tree = RBTree()
bid_tree = RBTree()


def draw(*args):
    ask_x = list(ask_tree.keys())
    ask_y = list(ask_tree.values())
    plt.figure()
    plt.plot(ask_x, ask_y)
    plt.savefig("ob.png")


def on_message(ws, message):
    payload = json.loads(message)

    if payload['cmd'] == 'partial':
        for pri_vol in payload['bids']:
            bid_tree.insert(Decimal(pri_vol[0]), Decimal(pri_vol[1]))
        for pri_vol in payload['asks']:
            ask_tree.insert(Decimal(pri_vol[0]), Decimal(pri_vol[1]))
    elif payload['cmd'] == 'update':
        for pri_vol in payload['bids']:
            price = Decimal(pri_vol[0])
            if bid_tree.get(price) != None:
                if price == 0:
                    bid_tree.remove(price)
                else:
                    bid_tree.update([(price, Decimal(pri_vol[1]))])
            else:
                bid_tree.insert(price, Decimal(pri_vol[1]))
        for pri_vol in payload['asks']:
            price = Decimal(pri_vol[0])
            if ask_tree.get(price) != None:
                if price == 0:
                    ask_tree.remove(price)
                else:
                    ask_tree.update([(price, Decimal(pri_vol[1]))])
            else:
                ask_tree.insert(price, Decimal(pri_vol[1]))
    # print(list(bid_tree.items()))
    # print(list(ask_tree.items()))
    # ask_max_item = ask_tree.max_item()
    # bid_max_item = bid_tree.max_item()
    # ask_min_item = ask_tree.min_item()
    # bid_min_item = bid_tree.min_item()

    # ask_x_max = ask_max_item[0]
    # ask_y_max = ask_max_item[1]
    # ask_x_min = ask_min_item[0]
    # ask_y_min = ask_min_item[1]

    # counter = random.randint(1, 10)
    draw()


def on_error(ws, error):
    print(error)


def on_close(ws):
    print("### closed ###")


def on_open(ws):
    def run(*args):
        sub_data = {
            "cmd": "sub",
            "payload": {
                "name": "bitmex_XBTUSD"
            }
        }
        ws.send(json.dumps(sub_data))
    thread.start_new_thread(run, ())


if __name__ == "__main__":
    websocket.enableTrace(True)
    ws = websocket.WebSocketApp("ws://127.0.0.1:6389",
                                on_message=on_message,
                                on_error=on_error,
                                on_close=on_close)
    ws.on_open = on_open
    ws.run_forever()
