from tinyrpc.protocols.jsonrpc import JSONRPCProtocol
from tinyrpc.transports.http import HttpPostClientTransport
from tinyrpc import RPCClient
import time


def main():
    rpc_client = RPCClient(
        JSONRPCProtocol(),
        HttpPostClientTransport('http://localhost:8484/jsonrpc'))

    response = rpc_client.call(method="GetVVCInfo", args=None, kwargs=None)
    print(f"VVC info: {response}")

    response = rpc_client.call(method="UartTransmit", args=None, kwargs={'data': [0xAA, 0xBB, 0xCC, 0xDD]}, one_way=False)
    print(f"response = {response}")

    time.sleep(1.0)

    response = rpc_client.call(method="UartReceive", args=None, kwargs={'length': 4, 'all_or_nothing': False}, one_way=False)
    print(f"response = {response}")


if __name__ == '__main__':
    main()

