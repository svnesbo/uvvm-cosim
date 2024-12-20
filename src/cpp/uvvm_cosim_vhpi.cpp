#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <deque>
#include <thread>
#include <vector>
#include <vhpi_user.h>
#include "uvvm_cosim_server.h"
#include "shared_vector.h"

#include <cpphttplibconnector.hpp>

#ifdef __cplusplus
extern "C" {
#endif


// UART transmit and receive queues
// Shared between server and VHPI/VHDL
//std::deque<uint8_t> uart_transmit_queue;
//std::deque<uint8_t> uart_receive_queue;
shared_vector<uint8_t> uart_transmit_queue;
shared_vector<uint8_t> uart_receive_queue;

// ----------------------------------------------------------------------------
// SERVER FUNCTIONS - UART
// ----------------------------------------------------------------------------


UVVMCosimServer cosimServerMethods(uart_transmit_queue, uart_receive_queue); // Todo: rename this class?
jsonrpccxx::JsonRpc2Server rpcServer;
CppHttpLibServerConnector* httpServer = NULL;

void start_rpc_server(void)
{
  std::cout << "Starting JSON RPC server" << std::endl;

  rpcServer.Add("UartTransmit", jsonrpccxx::GetHandle(&UVVMCosimServer::UartTransmit, cosimServerMethods), {"data"});
  rpcServer.Add("UartReceive", jsonrpccxx::GetHandle(&UVVMCosimServer::UartReceive, cosimServerMethods), {"length"});

  httpServer = new CppHttpLibServerConnector(rpcServer, 8484);

  std::cout << "Start listening on HTTP server" << std::endl;
  httpServer->StartListening();

  // Add some data to receive queue
  // Just for testing (so it can be received by example client)
  uart_receive_queue([](auto &v) {
		       v.push_back(0x12);
		       v.push_back(0x34);
		       v.push_back(0x56);
		       v.push_back(0x78);
		       v.push_back(0x99);
		       v.push_back(0xAA);
		       v.push_back(0xAB);
		       v.push_back(0xCD);
		     });
}

void stop_rpc_server(void)
{
  std::cout << "Stop listening on HTTP server" << std::endl;
  httpServer->StopListening();
  std::cout << "HTTP server stopped" << std::endl;
}


// ----------------------------------------------------------------------------
// VHPI FUNCTIONS - UART
// ----------------------------------------------------------------------------

//bool uart_transmit_queue_empty(void)
void uart_transmit_queue_empty(const vhpiCbDataT* p_cb_data)
{
}

//uint8_t uart_transmit_queue_pop(void)
void uart_transmit_queue_pop(const vhpiCbDataT* p_cb_data)
{
}

// Maybe I don't need uart_transmit_queue_empty?
// Sufficient to have the pop function (or call it get byte or something)
// and have that return a status (bool) as well as a byte?
// (use parameters as outputs?)



//void func(int a, int b)
void func(const vhpiCbDataT* p_cb_data)
{
  printf("func called\n");

  vhpiHandleT h_param0 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 0);
  vhpiHandleT h_param1 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 1);
  vhpiValueT val_param0 = {.format = vhpiIntVal };
  vhpiValueT val_param1 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param0, &val_param0) != 0) {
    printf("Failed to get param 0\n");
  }
  if (vhpi_get_value(h_param1, &val_param1) != 0) {
    printf("Failed to get param 1\n");
  }

  printf("Called with params: %d, %d.\n", val_param0.value.intg, val_param1.value.intg);

  vhpiValueT ret_val = {
    .format = vhpiIntVal,
    .value = { .intg = val_param0.value.intg * val_param1.value.intg }
  };
  vhpi_put_value(p_cb_data->obj, &ret_val, vhpiDeposit);
}

void startup_1(void)
{
  printf("startup_1 called\n");

  static char vhpi_lib_name[] = "vhpi_lib";
  static char vhpi_func_name[] = "vhpi_func";

  vhpiForeignDataT foreignData = {
    // vhpi_lib: VHDL library name
    // func_dec: VHDL function name
    vhpiFuncF, vhpi_lib_name, vhpi_func_name, NULL, func
  };

  vhpiHandleT h = vhpi_register_foreignf(&foreignData);

  vhpiForeignDataT check;

  if (vhpi_get_foreignf_info(h, &check)) {
    vhpi_printf("vhpi_get_foreignf_info failed\n");
  }

  if (check.kind != vhpiFuncF) {
    vhpi_printf("Wrong kind registered for foreign function\n");
  }

  if (strcmp(check.modelName, "vhpi_func") != 0) {
    vhpi_printf("Wrong model name registered for foreign function\n");
  }
}

long convert_time_to_ns(const vhpiTimeT *time)
{
  return (((long)time->high << 32) | (long)time->low) / 1000000;
}

void start_of_sim_cb(const vhpiCbDataT * cb_data) {
  vhpi_printf("Start of simulation\n");
  start_rpc_server();
}

void end_of_sim_cb(const vhpiCbDataT * cb_data) {
  vhpiTimeT t;
  long cycles;

  vhpi_get_time(&t, &cycles);
  vhpi_printf("End of simulation (after %ld cycles and %ld ns).\n", cycles, convert_time_to_ns(&t));

  using namespace std::chrono_literals;
  vhpi_printf("Wait for a while so we can test client...");
  std::this_thread::sleep_for(60.0s);

  stop_rpc_server();
}

void startup_2()
{
  vhpi_printf("startup_2\n");

  vhpiCbDataT cb_data;

  cb_data.reason = vhpiCbStartOfSimulation;
  cb_data.cb_rtn = start_of_sim_cb;
  cb_data.obj = NULL;
  cb_data.time = NULL;
  cb_data.value = NULL;
  cb_data.user_data = NULL;

  vhpi_register_cb(&cb_data, 0);

  cb_data.reason = vhpiCbEndOfSimulation;
  cb_data.cb_rtn = end_of_sim_cb;

  static vhpiTimeT t = {.high = 0, .low = 250};
  cb_data.time = &t;

  vhpi_register_cb(&cb_data, 0);
}


void (*vhpi_startup_routines[])() = {
  startup_1,
  startup_2,
  NULL
};


#ifdef __cplusplus
}
#endif
