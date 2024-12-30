#include <cstdint>
#include <iostream>
#include <thread>
#include <vector>
#include <jsonrpccxx/client.hpp>
#include <jsonrpccxx/iclientconnector.hpp>
#include <cpphttplibconnector.hpp>
#include "uvvm_cosim_types.h"


// Example client for UVVM cosim
// Implements method for UART transmit and receive currently
class UVVMCosimExampleClient : private jsonrpccxx::JsonRpcClient {
public:
  explicit UVVMCosimExampleClient(jsonrpccxx::IClientConnector &connector)
    : jsonrpccxx::JsonRpcClient(connector, jsonrpccxx::version::v2)
  {
  }

  std::vector<VVCInfo> GetVVCInfo() {
    return CallMethod<std::vector<VVCInfo>>(1, "GetVVCInfo", {});
  }

  bool UartTransmit(std::vector<uint8_t> data)
  {
    return CallMethod<bool>(1, "UartTransmit", {data});
  }

  std::vector<uint8_t> UartReceive(unsigned int length, bool all_or_nothing)
  {
    return CallMethod<std::vector<uint8_t>>(1, "UartReceive", {length, all_or_nothing});
  }
};


void print_received_data(const std::vector<uint8_t>& data)
{
  std::cout << "data = [";
  bool first = true;
  for (auto &b : data) {
    if (!first) {
      std::cout << ",";
    }
    std::cout << std::hex << (int)b;
    first = false;
  }
  std::cout << "]" << std::endl << std::dec;
}

// Test connecting, transmitting and receiving some bytes
int main(int argc, char** argv)
{
  using namespace std::chrono_literals;

  CppHttpLibClientConnector http_connector("localhost", 8484);
  std::this_thread::sleep_for(0.5s);

  UVVMCosimExampleClient client(http_connector);

  std::cout << "Wait a bit more...." << std::endl;

  std::this_thread::sleep_for(0.5s);

  std::cout << "Transmit some data..." << std::endl;

  client.UartTransmit({0xCA, 0xFE, 0xAA, 0x12, 0x34, 0x55});

  // Assume data has been transmitted/received after 1.0 seconds
  std::this_thread::sleep_for(1.0s);

  std::cout << "Request to receive 5 bytes..." << std::endl;
  {
    auto data = client.UartReceive(5, false);
    std::cout << "Got " << data.size() << " bytes." << std::endl;
    if (!data.empty()) {
      print_received_data(data);
    }
  }

  std::cout << "Request to receive 5 bytes (more than available)..." << std::endl;
  {
    auto data = client.UartReceive(5, true);
    std::cout << "Got " << data.size() << " bytes." << std::endl;
    if (!data.empty()) {
      print_received_data(data);
    }
  }

  std::cout << "Request to receive 5 bytes or whatever is available..." << std::endl;
  {
    auto data = client.UartReceive(5, false);
    std::cout << "Got " << data.size() << " bytes." << std::endl;
    if (!data.empty()) {
      print_received_data(data);
    }
  }

  // Transmit some more data
  client.UartTransmit({0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC});
  client.UartTransmit({0x01, 0x02, 0x03, 0x04, 0x05, 0x06});

  // Assume data has been transmitted/received after 1.0 seconds
  std::this_thread::sleep_for(1.0s);

  std::cout << "Request to receive 12 bytes or whatever is available..." << std::endl;
  {
    auto data = client.UartReceive(12, false);
    std::cout << "Got " << data.size() << " bytes." << std::endl;
    if (!data.empty()) {
      print_received_data(data);
    }
  }

  // Transmit some more data
  client.UartTransmit({0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C});
  client.UartTransmit({0x0D, 0x0E, 0x0F, 0x10, 0x11, 0x12});

  // Assume data has been transmitted/received after 1.0 seconds
  std::this_thread::sleep_for(1.0s);

  std::cout << "Request to receive 12 bytes or whatever is available..." << std::endl;
  {
    auto data = client.UartReceive(12, false);
    std::cout << "Got " << data.size() << " bytes." << std::endl;
    if (!data.empty()) {
      print_received_data(data);
    }
  }

  std::cout << "Get info about VVCs" << std::endl;
  auto vvc_info = client.GetVVCInfo();

  for (auto& vvc : vvc_info) {
    std::cout << "Type: " << vvc.vvc_type << ", ";
    std::cout << "Channel: " << vvc.vvc_channel << ", ";
    std::cout << "Instance ID: " << vvc.vvc_instance_id << std::endl;
  }
}
