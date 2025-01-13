import requests
import time


def main():
    url = "http://localhost:8484/jsonrpc"

    payload = {
        "method": "GetVvcList",
        "params": [],
        "jsonrpc": "2.0",
        "id": 0,
    }
    response = requests.post(url, json=payload).json()
    print(f"VVC list response: {response}")

    payload = {
        "method": "TransmitBytes",
        "params": {"vvc_type": "UART_VVC",
                   "vvc_id": 0,
                   "data": [0x12, 0x34, 0x56, 0x78, 0x9A]},
        "jsonrpc": "2.0",
        "id": 1,
    }
    response = requests.post(url, json=payload).json()
    print(f"response = {response}")

    time.sleep(1.0)

    payload = {
        "method": "ReceiveBytes",
        "params": {"vvc_type": "UART_VVC",
                   "vvc_id": 1,
                   "length": 5,
                   "all_or_nothing": False},
        "jsonrpc": "2.0",
        "id": 2,
    }
    response = requests.post(url, json=payload).json()
    print(f"response = {response}")


if __name__ == "__main__":
    main()
