#include <cstdint>
#include <iostream>
#include <vector>
#include "shared_vector.h"


class UVVMCosimServer {
private:
  // Todo: Use deque instead
  shared_vector<uint8_t> &transmit_queue;
  shared_vector<uint8_t> &receive_queue;
  
public:
  UVVMCosimServer(shared_vector<uint8_t> &transmit_queue,
			shared_vector<uint8_t> &receive_queue)
    : transmit_queue(transmit_queue)
    , receive_queue(receive_queue)
  {
  }

  bool UartTransmit(std::vector<uint8_t> data) {
    std::cout << "Server: Got some data to transmit: [";
    bool first=true;
    for (auto &b : data) {
      if (!first) {
	std::cout << ",";
      }
      std::cout << std::hex << (int) b;
      first=false;
    }
    std::cout << "]" << std::endl;

    transmit_queue([&](auto &v) { v.insert(v.end(), data.begin(), data.end()); });

    // Todo: Return true only if queue is not full?
    return true;
  }

  std::vector<uint8_t> UartReceive(unsigned int length) {
    std::vector<uint8_t> data;

    // Move as much data as is available, up to length bytes, from
    // uart_receive_queue into data.
    receive_queue([&](auto &v) {
		    if (v.size() > length) {
		      std::cout << "Server: Returning requested length=" << length << " bytes of data to client" << std::endl;
		      data.insert(data.begin(), v.begin(), v.begin()+length);

		      // Todo: Probably a better way to move instead of copy + erase
		      v.erase(v.begin(), v.begin()+length);
		    } else {
		      std::cout << "Server: Return " << v.size() << " available bytes (" << length << " bytes was requested)" << std::endl;

		      data.insert(data.begin(), v.begin(), v.end());

		      // Todo: Probably a better way to move instead of copy + erase
		      v.erase(v.begin(), v.end());
		    }
		  });

    return data;
  }
  
};
  
