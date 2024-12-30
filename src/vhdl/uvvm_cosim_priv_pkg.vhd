-- Package with internal (private) definitions used by uvvm cosim scheduler
-- Not intended to be used by user

library uvvm_util;
context uvvm_util.uvvm_util_context;

package uvvm_cosim_priv_pkg is

  procedure uvvm_cosim_vhpi_start_sim;

  procedure uvvm_cosim_vhpi_report_vvc_info(
    constant vvc_type        : in string;
    constant vvc_channel     : in string;
    constant vvc_instance_id : in integer
    );

  function uart_transmit_queue_empty return integer;

  function uart_transmit_queue_get return integer;

  procedure uart_receive_queue_put(constant byte : in integer);

  attribute foreign of uvvm_cosim_vhpi_start_sim       : procedure is "VHPI vhpi_lib uvvm_cosim_vhpi_start_sim";
  attribute foreign of uvvm_cosim_vhpi_report_vvc_info : procedure is "VHPI vhpi_lib uvvm_cosim_vhpi_report_vvc_info";
  attribute foreign of uart_transmit_queue_empty       : function  is "VHPI vhpi_lib uart_transmit_queue_empty";
  attribute foreign of uart_transmit_queue_get         : function  is "VHPI vhpi_lib uart_transmit_queue_get";
  attribute foreign of uart_receive_queue_put          : procedure is "VHPI vhpi_lib uart_receive_queue_put";


  function to_string(constant ch : t_channel) return string;

end package uvvm_cosim_priv_pkg;


package body uvvm_cosim_priv_pkg is

  procedure uvvm_cosim_vhpi_start_sim is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end procedure;

  procedure uvvm_cosim_vhpi_report_vvc_info(
    constant vvc_type        : in string;
    constant vvc_channel     : in string;
    constant vvc_instance_id : in integer
    ) is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end procedure;

  function uart_transmit_queue_empty return integer is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end function;

  function uart_transmit_queue_get return integer is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end function;

  procedure uart_receive_queue_put(
    constant byte : in integer
    ) is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end procedure;


  function to_string(
    constant ch : t_channel
    ) return string is
    constant C_NA           : string := "NA";
    constant C_ALL_CHANNELS : string := "ALL_CHANNELS";
    constant C_RX           : string := "RX";
    constant C_TX           : string := "TX";
  begin
    case ch is
      when NA =>
        return C_NA;
      when ALL_CHANNELS =>
        return C_ALL_CHANNELS;
      when RX =>
        return C_RX;
      when TX =>
        return C_TX;
      when others =>
        report "Unknown channel type" severity failure;
        return "";
    end case;
  end function to_string;

end package body uvvm_cosim_priv_pkg;
