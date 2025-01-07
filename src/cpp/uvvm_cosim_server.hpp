#pragma once
#include <cstdint>
#include <iostream>
#include <vector>
#include <jsonrpccxx/server.hpp>
#include <cpphttplibconnector.hpp>
#include "shared_deque.hpp"
#include "shared_vector.hpp"
#include "uvvm_cosim_types.hpp"

class UvvmCosimServer {
private:
  // Todo: Use deque instead
  shared_deque<uint8_t> &uart_transmit_queue;
  shared_deque<uint8_t> &uart_receive_queue;
  shared_deque<uint8_t> &axis_transmit_queue;
  shared_deque<uint8_t> &axis_receive_queue;
  shared_vector<VvcInstance> &vvc_list;

  jsonrpccxx::JsonRpc2Server jsonRpcServer;

  CppHttpLibServerConnector *httpServer = NULL;

public:
  UvvmCosimServer(shared_deque<uint8_t> &uart_transmit_queue,
		  shared_deque<uint8_t> &uart_receive_queue,
		  shared_deque<uint8_t> &axis_transmit_queue,
		  shared_deque<uint8_t> &axis_receive_queue,
		  shared_vector<VvcInstance> &vvc_list)
    : uart_transmit_queue(uart_transmit_queue)
    , uart_receive_queue(uart_receive_queue)
    , axis_transmit_queue(axis_transmit_queue)
    , axis_receive_queue(axis_receive_queue)
    , vvc_list(vvc_list)
  {
    using namespace jsonrpccxx;

    // Add JSON-RPC procedures

    jsonRpcServer.Add("UartTransmit",
                      GetHandle(&UvvmCosimServer::UartTransmit, *this),
                      {"data"});

    jsonRpcServer.Add("UartReceive",
                      GetHandle(&UvvmCosimServer::UartReceive, *this),
                      {"length", "all_or_nothing"});

    jsonRpcServer.Add("AxistreamTransmit",
                      GetHandle(&UvvmCosimServer::AxistreamTransmit, *this),
                      {"data"});

    jsonRpcServer.Add("AxistreamReceive",
                      GetHandle(&UvvmCosimServer::AxistreamReceive, *this),
                      {"length", "all_or_nothing"});

    jsonRpcServer.Add("GetVvcList",
                      GetHandle(&UvvmCosimServer::GetVvcList, *this), {});

    httpServer = new CppHttpLibServerConnector(jsonRpcServer, 8484);
  }

  ~UvvmCosimServer()
  {
    httpServer->StopListening();
    delete httpServer;
  }

  void StartListening()
  {
    httpServer->StartListening();
  }

  void StopListening()
  {
    httpServer->StopListening();
  }

private:
  // --------------------------------------------------------------------------
  // JSON-RPC remote procedures
  // --------------------------------------------------------------------------

  std::vector<VvcInstance> GetVvcList() {
    return vvc_list([](auto v){return v;});
  }

  bool UartTransmit(std::vector<uint8_t> data) {
    std::cout << "Server [UART]: Got some data to transmit: [";
    bool first=true;
    for (auto &b : data) {
      if (!first) {
	std::cout << ",";
      }
      std::cout << std::hex << (int) b;
      first=false;
    }
    std::cout << "]" << std::endl << std::dec;

    uart_transmit_queue([&](auto &q) { q.insert(q.end(), data.begin(), data.end()); });

    // Todo: Return true only if queue is not full?
    return true;
  }

  std::vector<uint8_t> UartReceive(unsigned int length, bool all_or_nothing) {
    std::vector<uint8_t> data;

    // Move as much data as is available, up to length bytes, from
    // uart_receive_queue into data.
    uart_receive_queue([&](auto &q) {
      if (q.size() > length) {
        std::cout << "Server [UART]: Returning requested length=" << length
                  << " bytes of data to client" << std::endl;
        data.insert(data.begin(), q.begin(), q.begin() + length);

        // Todo: Probably a better way to move instead of copy + erase
        q.erase(q.begin(), q.begin() + length);
      } else if (q.size() == length || !all_or_nothing) {
        std::cout << "Server [UART]: Return " << q.size() << " available bytes ("
                  << length << " bytes was requested)" << std::endl;

        data.insert(data.begin(), q.begin(), q.end());

        // Todo: Probably a better way to move instead of copy + erase
        q.erase(q.begin(), q.end());
      }
    });

    return data;
  }

  bool AxistreamTransmit(std::vector<uint8_t> data) {
    std::cout << "Server [AXI-S]: Got some data to transmit: [";
    bool first=true;
    for (auto &b : data) {
      if (!first) {
	std::cout << ",";
      }
      std::cout << std::hex << (int) b;
      first=false;
    }
    std::cout << "]" << std::endl << std::dec;

    axis_transmit_queue([&](auto &q) { q.insert(q.end(), data.begin(), data.end()); });

    // Todo: Return true only if queue is not full?
    return true;
  }

  std::vector<uint8_t> AxistreamReceive(unsigned int length, bool all_or_nothing) {
    std::vector<uint8_t> data;

    // Move as much data as is available, up to length bytes, from
    // axis_receive_queue into data.
    axis_receive_queue([&](auto &q) {
      if (q.size() > length) {
        std::cout << "Server [AXI-S]: Returning requested length=" << length
                  << " bytes of data to client" << std::endl;
        data.insert(data.begin(), q.begin(), q.begin() + length);

        // Todo: Probably a better way to move instead of copy + erase
        q.erase(q.begin(), q.begin() + length);
      } else if (q.size() == length || !all_or_nothing) {
        std::cout << "Server [AXI-S]: Return " << q.size() << " available bytes ("
                  << length << " bytes was requested)" << std::endl;

        data.insert(data.begin(), q.begin(), q.end());

        // Todo: Probably a better way to move instead of copy + erase
        q.erase(q.begin(), q.end());
      }
    });

    return data;
  }
};
  
