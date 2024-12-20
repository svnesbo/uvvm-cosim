# UVVM Co-simulation library using VHPI and JSON-RPC

## Project name

- ~~uvvm-rpc-cosim?~~
- ~~uvvm-json-rpc-cosim?~~
- ~~uvvm-cosim?~~
- ~~uvvm-json-rpc?~~

~~For now I think I'll go with:~~
- ~~Project name: uvvm-cosim-json-rpc~~
- ~~Library name (VHPI): uvvm-cosim-vhpi~~


Decided to use this name: **uvvm-cosim**


## JSON-RPC libraries in C++

Instructions to build and test:

```
mkdir build
cd build
cmake ..
make
make nvc_sim
```


### libjson-rpc-cpp

URL: https://github.com/cinemast/libjson-rpc-cpp

Very full featured C++ implementation of JSON-RPC. Packages are available for several Linux distros (Ubuntu, Fedora, etc).

It also supports a way to write a specification file (in JSON) for the client and server, and it can generate a stub and client that implements the necessary methods.

There are several good examples for this library as well, under src/examples, and connectors are implemented for several interfaces: HTTP, serial port, Windows and Linux TCP sockets, UNIX domain sockets, Redis, etc.

### libjson-rpc-cxx

URL: https://github.com/jsonrpcx/json-rpc-cxx

By the same author as libjson-rpc-cpp, this is a header-only implementation that utilizes more modern C++17 features. It also uses nlohmann's json for modern C++ library.

It seems fairly easy to use. But it is in my opinion a bit weird how it is used/implemented:
- JsonRpcClient implements the methods you want to call on the server
  - You use an "Add" method to add the remote methods before you can use them
- JsonRpcClient communicates via a connector of derived from type IClientConnector
- IClientConnector implements a single function Send():
  - std::string Send(const std::string &request)
- Any derived ClientConnector class that implements Send for a specific transport (e.g. sockets, HTTP) has to:
  - Transmit the request data when Send is called
  - Wait for response data - you somehow have to know that you've received the full response
  - Return the response data as a string from Send()

To me it seems a bit clumsy to work with. Especially if I wanted to implement this asynchronously. For example, I may want to be able to send several requests and get the responses later?
I don't know, maybe that is the "wrong" way to think about RPC. Maybe in RPC when you call a method, you are supposed to wait for it finish and get the response before you do something else??

Anyway, I pretty much agree with this issue on GitHub:
https://github.com/jsonrpcx/json-rpc-cxx/issues/34

THAT BEING SAID, FOR NOW I WILL USE THIS FRAMEWORK.
It is pretty easy to set up. And it is ok for now that I need the response immediately. In the RPC server I will just put the data right into a queue and send the response right away, so there won't be a long wait.

But in the future I may want to support both sync and async RPC calls. The packio (below) library may be a good solution to that.

### packio

URL: https://github.com/qchateau/packio/tree/master

Supports sync and async msgpack-RPC and JSON RPC.

Supports/uses nlohmann's json library.

Based on C++17/20.

Uses boost:asio (so there are boost dependencies).

Looks like a very nice library. BUT, it does have the Boost dependency.

A couple of basic examples are available under test_package/samples.
