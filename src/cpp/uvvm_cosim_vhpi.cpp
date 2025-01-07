#include <exception>
#include <iostream>
#include <deque>
#include <string>
#include <thread>
#include <vector>
#include <vhpi_user.h>
#include "uvvm_cosim_server.hpp"
#include "uvvm_cosim_types.hpp"
#include "shared_deque.hpp"
#include "shared_vector.hpp"

extern "C" {

// UART transmit and receive queues
// Shared between server and VHPI/VHDL
shared_deque<uint8_t> uart_transmit_queue;
shared_deque<uint8_t> uart_receive_queue;

// AXI-Stream transmit and receive queues
// Shared between server and VHPI/VHDL
shared_deque<uint8_t> axis_transmit_queue;
shared_deque<uint8_t> axis_receive_queue;

// List of VVCs in the simulation
shared_vector<VvcInstance> vvc_list;

// ----------------------------------------------------------------------------
// SERVER FUNCTIONS - UART
// ----------------------------------------------------------------------------

// Todo: rename this class?
UvvmCosimServer cosim_server(uart_transmit_queue, uart_receive_queue,
                             axis_transmit_queue, axis_receive_queue, vvc_list);

CppHttpLibServerConnector* httpServer = NULL;

void start_rpc_server(void)
{
  std::cout << "Start JSON RPC server" << std::endl;
  cosim_server.StartListening();
}

void stop_rpc_server(void)
{
  std::cout << "Stop JSON RPC server" << std::endl;
  cosim_server.StopListening();
  std::cout << "JSON RPC server stopped" << std::endl;
}


// ----------------------------------------------------------------------------
// VHPI FUNCTIONS - UART
// ----------------------------------------------------------------------------


// Maybe I don't need uart_transmit_queue_empty?
// Sufficient to have the pop function (or call it get byte or something)
// and have that return a status (bool) as well as a byte?
// (use parameters as outputs?)

//int uart_transmit_queue_empty(void)
void uart_transmit_queue_empty(const vhpiCbDataT* p_cb_data)
{
  vhpiHandleT h_param0 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 0);
  vhpiValueT val_param0 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param0, &val_param0) != 0) {
    vhpi_printf("Failed to get param 0");
  }

  // NOTE: vvc_idx not used yet
  int vvc_idx = val_param0.value.intg;

  bool empty = uart_transmit_queue([](auto &q) { return q.empty(); });

  // NOTE: Hardcoded for VVC ID 0 for now!
  if (vvc_idx != 0) {
    empty = true;
  }

  // Todo: Is there a more appropriate format for a boolean than vhpiIntVal?
  vhpiValueT ret_val = {
    .format = vhpiIntVal,
    .value = { .intg = (empty ? 1 : 0) }
  };
  vhpi_put_value(p_cb_data->obj, &ret_val, vhpiDeposit);
}

//uint8_t uart_transmit_queue_get(void)
void uart_transmit_queue_get(const vhpiCbDataT* p_cb_data)
{
  vhpiHandleT h_param0 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 0);
  vhpiValueT val_param0 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param0, &val_param0) != 0) {
    vhpi_printf("Failed to get param 0");
  }

  // NOTE: vvc_idx not used yet
  int vvc_idx = val_param0.value.intg;

  uint8_t byte = 0;
  uart_transmit_queue([&](auto &q) {
			if (q.empty()) {
			  vhpi_assert(vhpiError,
				     "uart_transmit_queue_get called on empty queue");
			}
			byte = q.front(); q.pop_front();
		      });

  // Todo: Is there a more appropriate format for a byte than vhpiIntVal?
  vhpiValueT ret_val = {
    .format = vhpiIntVal,
    .value = { .intg = byte }
  };
  vhpi_put_value(p_cb_data->obj, &ret_val, vhpiDeposit);
}

//void uart_receive_queue_put(uint8_t byte)
void uart_receive_queue_put(const vhpiCbDataT* p_cb_data)
{
  vhpiHandleT h_param0 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 0);
  vhpiValueT val_param0 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param0, &val_param0) != 0) {
    vhpi_printf("Failed to get param 0");
  }

  vhpiHandleT h_param1 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 1);
  vhpiValueT val_param1 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param1, &val_param1) != 0) {
    vhpi_printf("Failed to get param 1");
  }

  // NOTE: vvc_idx not used yet
  int vvc_idx = val_param0.value.intg;
  // Todo: Is there a more appropriate parameter format for a byte than vhpiIntVal?
  uint8_t byte = val_param1.value.intg;

  uart_receive_queue([&](auto &q) { q.push_back(byte); });
}

//int axis_transmit_queue_empty(void)
void axis_transmit_queue_empty(const vhpiCbDataT* p_cb_data)
{
  vhpiHandleT h_param0 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 0);
  vhpiValueT val_param0 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param0, &val_param0) != 0) {
    vhpi_printf("Failed to get param 0");
  }

  // NOTE: vvc_idx not used yet
  int vvc_idx = val_param0.value.intg;

  bool empty = axis_transmit_queue([](auto &q) { return q.empty(); });

  // NOTE: Hardcoded for VVC ID 0 for now!
  if (vvc_idx != 0) {
    empty = true;
  }

  // Todo: Is there a more appropriate format for a boolean than vhpiIntVal?
  vhpiValueT ret_val = {
    .format = vhpiIntVal,
    .value = { .intg = (empty ? 1 : 0) }
  };
  vhpi_put_value(p_cb_data->obj, &ret_val, vhpiDeposit);
}

//uint8_t axis_transmit_queue_get(void)
void axis_transmit_queue_get(const vhpiCbDataT* p_cb_data)
{
  vhpiHandleT h_param0 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 0);
  vhpiValueT val_param0 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param0, &val_param0) != 0) {
    vhpi_printf("Failed to get param 0");
  }

  // NOTE: vvc_idx not used yet
  int vvc_idx = val_param0.value.intg;

  uint8_t byte = 0;
  axis_transmit_queue([&](auto &q) {
			if (q.empty()) {
			  vhpi_assert(vhpiError,
				     "axis_transmit_queue_get called on empty queue");
			}
			byte = q.front(); q.pop_front();
		      });

  // Todo: Is there a more appropriate format for a byte than vhpiIntVal?
  vhpiValueT ret_val = {
    .format = vhpiIntVal,
    .value = { .intg = byte }
  };
  vhpi_put_value(p_cb_data->obj, &ret_val, vhpiDeposit);
}

//void axis_receive_queue_put(uint8_t byte)
void axis_receive_queue_put(const vhpiCbDataT* p_cb_data)
{
  vhpiHandleT h_param0 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 0);
  vhpiValueT val_param0 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param0, &val_param0) != 0) {
    vhpi_printf("Failed to get param 0");
  }

  vhpiHandleT h_param1 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 1);
  vhpiValueT val_param1 = {.format = vhpiIntVal };

  if (vhpi_get_value(h_param1, &val_param1) != 0) {
    vhpi_printf("Failed to get param 1");
  }

  // NOTE: vvc_idx not used yet
  int vvc_idx = val_param0.value.intg;
  // Todo: Is there a more appropriate parameter format for a byte than vhpiIntVal?
  uint8_t byte = val_param1.value.intg;

  axis_receive_queue([&](auto &q) { q.push_back(byte); });
}


void uvvm_cosim_vhpi_start_sim(const vhpiCbDataT* p_cb_data)
{
  vhpi_printf("uvvm_cosim_vhpi_start_sim: Waiting to start sim");

  using namespace std::chrono_literals;
  std::this_thread::sleep_for(2.0s);

  vhpi_printf("uvvm_cosim_vhpi_start_sim: Starting sim");
}

// Split a string by delimiter into substrings.
// Unnecessary leading/trailing and extra delimiters are removed
std::vector<std::string> split(std::string str, std::string delim)
{
  std::vector<std::string> substrings;

  size_t next_pos;

  while ((next_pos = str.find_first_not_of(delim)) != std::string::npos) {
    str.erase(0, next_pos);

    size_t delim_pos = str.find_first_of(delim);
    substrings.push_back(str.substr(0, delim_pos));
    str.erase(0, delim_pos);
  }

  return substrings;
}

// Search a comma-separated string for config values
// Each config value must be a key/value pair formatted as "key=value"
// Only integers are supported for value (use 0/1 for bool).
// Example string:
// "packet_based=1,enabled=0,timeout=1000"
std::map<std::string, int> parse_vvc_cfg_str(const std::string& cfg_str)
{
  std::map<std::string, int> vvc_cfg;

  try {
    auto cfg_items = split(cfg_str, ",");

    for (auto &cfg_item : cfg_items) {

      std::cout << "cfg_item=\"" << cfg_item << "\"" << std::endl;

      auto cfg_key_val = split(cfg_item, "=");

      if (cfg_key_val.size() != 2) {
        std::cerr << "Error parsing config item" << std::endl;
        continue;
      }

      std::string cfg_key = cfg_key_val[0];
      int cfg_val = std::stoi(cfg_key_val[1]);

      vvc_cfg.emplace(cfg_key, cfg_val);
    }

  } catch (std::exception &e) {
    std::cerr << "Exception processing config string \"" << cfg_str << "\".";
    std::cerr << "Reason=" << e.what() << std::endl;
  }

  return vvc_cfg;
}

void uvvm_cosim_vhpi_report_vvc_info(const vhpiCbDataT* p_cb_data)
{
  constexpr size_t C_MAX_STR_SIZE = 256;

  vhpiHandleT h_param0 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 0);
  vhpiHandleT h_param1 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 1);
  vhpiHandleT h_param2 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 2);
  vhpiHandleT h_param3 = vhpi_handle_by_index(vhpiParamDecls, p_cb_data->obj, 3);

  vhpiCharT str_param0[C_MAX_STR_SIZE];
  vhpiCharT str_param1[C_MAX_STR_SIZE];
  vhpiCharT str_param3[C_MAX_STR_SIZE];

  vhpiValueT val_param0 = {.format = vhpiStrVal };
  vhpiValueT val_param1 = {.format = vhpiStrVal };
  vhpiValueT val_param2 = {.format = vhpiIntVal };
  vhpiValueT val_param3 = {.format = vhpiStrVal };

  val_param0.bufSize=sizeof(str_param0);
  val_param0.value.str=str_param0;
  val_param1.bufSize=sizeof(str_param1);
  val_param1.value.str=str_param1;
  val_param3.bufSize=sizeof(str_param3);
  val_param3.value.str=str_param3;

  if (vhpi_get_value(h_param0, &val_param0) != 0) {
    vhpi_printf("Failed to get param 0");
  }
  if (vhpi_get_value(h_param1, &val_param1) != 0) {
    vhpi_printf("Failed to get param 1");
  }
  if (vhpi_get_value(h_param2, &val_param2) != 0) {
    vhpi_printf("Failed to get param 2");
  }
  if (vhpi_get_value(h_param3, &val_param3) != 0) {
    vhpi_printf("Failed to get param 3");
  }

  vhpi_printf("uvvm_cosim_vhpi_report_vvc_info: Got:");
  vhpi_printf("Type=%s, Channel=%s, ID=%d, cfg=%s",
	      val_param0.value.str,
              val_param1.value.str,
	      val_param2.value.intg,
	      val_param3.value.str);

  std::string cfg_str = std::string(reinterpret_cast<char*>(val_param3.value.str));
  auto vvc_cfg = parse_vvc_cfg_str(cfg_str);

  vvc_list([&](auto &v) {
    // Todo: I'd like to construct in place (with emplace_back)
    // How can I do that for struct? Does it need to have constructor maybe?
    v.push_back(VvcInstance{
        .vvc_type = std::string(reinterpret_cast<char *>(val_param0.value.str)),
        .vvc_channel = std::string(reinterpret_cast<char *>(val_param1.value.str)),
        .vvc_instance_id = val_param2.value.intg,
        .vvc_cfg = vvc_cfg});
    // Note: vhpiCharT is defined as unsigned char
    //       std::string doesn't have constructor for uchar
  });
}

void check_foreignf_registration(const vhpiHandleT& h, const char* func_name, vhpiForeignKindT kind)
{
  vhpiForeignDataT check;

  if (vhpi_get_foreignf_info(h, &check)) {
    vhpi_printf("vhpi_get_foreignf_info failed");
  }

  if (check.kind != kind) {
    vhpi_printf("Wrong kind registered for foreign function");
  }

  if (strcmp(check.modelName, func_name) != 0) {
    vhpi_printf("Wrong model name registered for foreign function");
  }
}

void startup_1(void)
{
  vhpi_printf("startup_1 called");

  static char vhpi_lib_name[] = "vhpi_lib";

  vhpiForeignDataT foreignData = {
    .libraryName = vhpi_lib_name,
    .elabf       = NULL
  };

  vhpiHandleT h;

  static char uvvm_cosim_vhpi_report_vvc_info_name[] = "uvvm_cosim_vhpi_report_vvc_info";
  foreignData.kind=vhpiProcF;
  foreignData.modelName=uvvm_cosim_vhpi_report_vvc_info_name;
  foreignData.execf=uvvm_cosim_vhpi_report_vvc_info;
  h = vhpi_register_foreignf(&foreignData);
  check_foreignf_registration(h, uvvm_cosim_vhpi_report_vvc_info_name, vhpiProcF);

  static char uvvm_cosim_vhpi_start_sim_name[] = "uvvm_cosim_vhpi_start_sim";
  foreignData.kind=vhpiProcF;
  foreignData.modelName=uvvm_cosim_vhpi_start_sim_name;
  foreignData.execf=uvvm_cosim_vhpi_start_sim;
  h = vhpi_register_foreignf(&foreignData);
  check_foreignf_registration(h, uvvm_cosim_vhpi_start_sim_name, vhpiProcF);

  static char uart_transmit_queue_empty_name[] = "uart_transmit_queue_empty";
  foreignData.kind=vhpiFuncF;
  foreignData.modelName=uart_transmit_queue_empty_name;
  foreignData.execf=uart_transmit_queue_empty;
  h = vhpi_register_foreignf(&foreignData);
  check_foreignf_registration(h, uart_transmit_queue_empty_name, vhpiFuncF);

  static char uart_transmit_queue_get_name[] = "uart_transmit_queue_get";
  foreignData.kind=vhpiFuncF;
  foreignData.modelName=uart_transmit_queue_get_name;
  foreignData.execf=uart_transmit_queue_get;
  h = vhpi_register_foreignf(&foreignData);
  check_foreignf_registration(h, uart_transmit_queue_get_name, vhpiFuncF);

  static char uart_receive_queue_put_name[] = "uart_receive_queue_put";
  foreignData.kind=vhpiProcF;
  foreignData.modelName=uart_receive_queue_put_name;
  foreignData.execf=uart_receive_queue_put;
  h = vhpi_register_foreignf(&foreignData);
  check_foreignf_registration(h, uart_receive_queue_put_name, vhpiProcF);

  static char axis_transmit_queue_empty_name[] = "axis_transmit_queue_empty";
  foreignData.kind=vhpiFuncF;
  foreignData.modelName=axis_transmit_queue_empty_name;
  foreignData.execf=axis_transmit_queue_empty;
  h = vhpi_register_foreignf(&foreignData);
  check_foreignf_registration(h, axis_transmit_queue_empty_name, vhpiFuncF);

  static char axis_transmit_queue_get_name[] = "axis_transmit_queue_get";
  foreignData.kind=vhpiFuncF;
  foreignData.modelName=axis_transmit_queue_get_name;
  foreignData.execf=axis_transmit_queue_get;
  h = vhpi_register_foreignf(&foreignData);
  check_foreignf_registration(h, axis_transmit_queue_get_name, vhpiFuncF);

  static char axis_receive_queue_put_name[] = "axis_receive_queue_put";
  foreignData.kind=vhpiProcF;
  foreignData.modelName=axis_receive_queue_put_name;
  foreignData.execf=axis_receive_queue_put;
  h = vhpi_register_foreignf(&foreignData);
  check_foreignf_registration(h, axis_receive_queue_put_name, vhpiProcF);

  vhpi_printf("Registered all foreign functions/procedures");
}

long convert_time_to_ns(const vhpiTimeT *time)
{
  return (((long)time->high << 32) | (long)time->low) / 1000000;
}

void start_of_sim_cb(const vhpiCbDataT * cb_data) {
  vhpi_printf("Start of simulation");
  start_rpc_server();
}

void end_of_sim_cb(const vhpiCbDataT * cb_data) {
  vhpiTimeT t;
  long cycles;

  vhpi_get_time(&t, &cycles);
  vhpi_printf("End of simulation (after %ld cycles and %ld ns).", cycles, convert_time_to_ns(&t));

  stop_rpc_server();
}

void startup_2()
{
  vhpi_printf("startup_2");

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
}
