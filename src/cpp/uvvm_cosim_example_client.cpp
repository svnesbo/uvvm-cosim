#include <cstdint>
#include <iostream>
#include <thread>
#include <vector>
#include <jsonrpccxx/client.hpp>
#include <jsonrpccxx/iclientconnector.hpp>
#include <cpphttplibconnector.hpp>


// Example client for UVVM cosim
// Implements method for UART transmit and receive currently
class UVVMCosimExampleClient : private jsonrpccxx::JsonRpcClient {
public:
  explicit UVVMCosimExampleClient(jsonrpccxx::IClientConnector &connector)
    : jsonrpccxx::JsonRpcClient(connector, jsonrpccxx::version::v2)
  {
  }

  bool UartTransmit(std::vector<uint8_t> data)
  {
    return CallMethod<bool>(1, "UartTransmit", {data});
  }

  std::vector<uint8_t> UartReceive(unsigned int length)
  {
    return CallMethod<std::vector<uint8_t>>(1, "UartReceive", {length});
  }
};


// Test connecting, transmitting and receiving some bytes
int main(int argc, char** argv)
{
  using namespace std::chrono_literals;

  CppHttpLibClientConnector http_connector("localhost", 8484);
  std::this_thread::sleep_for(0.5s);

  UVVMCosimExampleClient client(http_connector);

  std::cout << "Wait a bit more...." << std::endl;

  std::this_thread::sleep_for(0.5s);

  std::cout << "Transmit some data" << std::endl;

  client.UartTransmit({0xCA, 0xFE, 0xAA, 0x12, 0x34, 0x55});

  std::cout << "Receive some data" << std::endl;

  auto data = client.UartReceive(5);

  std::cout << "Got " << data.size() << " bytes." << std::endl;

  if (!data.empty()) {
    std::cout << "data = [";
    bool first=true;
    for (auto &b : data) {
      if (!first) {
	std::cout << ",";
      }
      std::cout << std::hex << (int) b;
      first=false;
    }
    std::cout << "]" << std::endl;
  }
}
