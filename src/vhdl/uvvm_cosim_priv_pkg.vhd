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

  -- TODO: Replace and add attribute for VHPI implementation
  function cosim_vvc_listen_enable (
    constant vvc_type        : string;
    constant vvc_channel     : string;
    constant vvc_instance_id : integer)
    return boolean;

  -- Todo:
  -- Replace dedicated uart/axis functions/procedures with common ones that takes
  -- VVC type as parameter. Can call them:
  -- * cosim_transmit_queue_empty
  -- * cosim_transmit_queue_get
  -- * cosim_receive_queue_put
  function uart_transmit_queue_empty(constant vvc_idx : in integer) return integer;

  function uart_transmit_queue_get(constant vvc_idx : in integer) return integer;

  procedure uart_receive_queue_put(constant vvc_idx : in integer;
                                   constant byte    : in integer);

  function axis_transmit_queue_empty(constant vvc_idx : in integer) return integer;

  function axis_transmit_queue_get(constant vvc_idx : in integer) return integer;

  procedure axis_receive_queue_put(constant vvc_idx : in integer;
                                   constant byte    : in integer);

  attribute foreign of uvvm_cosim_vhpi_start_sim       : procedure is "VHPI vhpi_lib uvvm_cosim_vhpi_start_sim";
  attribute foreign of uvvm_cosim_vhpi_report_vvc_info : procedure is "VHPI vhpi_lib uvvm_cosim_vhpi_report_vvc_info";
  attribute foreign of uart_transmit_queue_empty       : function  is "VHPI vhpi_lib uart_transmit_queue_empty";
  attribute foreign of uart_transmit_queue_get         : function  is "VHPI vhpi_lib uart_transmit_queue_get";
  attribute foreign of uart_receive_queue_put          : procedure is "VHPI vhpi_lib uart_receive_queue_put";
  attribute foreign of axis_transmit_queue_empty       : function  is "VHPI vhpi_lib axis_transmit_queue_empty";
  attribute foreign of axis_transmit_queue_get         : function  is "VHPI vhpi_lib axis_transmit_queue_get";
  attribute foreign of axis_receive_queue_put          : procedure is "VHPI vhpi_lib axis_receive_queue_put";


  function to_string(constant ch : t_channel) return string;
  function to_string(constant status : t_transaction_status) return string;

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

  -- TODO: Replace with VHPI implementation
  function cosim_vvc_listen_enable (
    constant vvc_type        : string;
    constant vvc_channel     : string;
    constant vvc_instance_id : integer)
    return boolean is
  begin
    -- Hardcoded to allow listen on UART VVC 1 and AXISTREAM VVC 1
    -- (setup for receive in the testbench and used in the client example)
    if (vvc_type = "UART_VVC" and vvc_channel = "RX" and vvc_instance_id = 1) or
      (vvc_type = "AXISTREAM_VVC" and vvc_instance_id = 1)
    then
      return true;
    else
      return false;
    end if;
  end;

  function uart_transmit_queue_empty(constant vvc_idx : in integer) return integer is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end function;

  function uart_transmit_queue_get(constant vvc_idx : in integer) return integer is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end function;

  procedure uart_receive_queue_put(
    constant vvc_idx : in integer;
    constant byte    : in integer
    ) is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end procedure;

  function axis_transmit_queue_empty(constant vvc_idx : in integer) return integer is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end function;

  function axis_transmit_queue_get(constant vvc_idx : in integer) return integer is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end function;

  procedure axis_receive_queue_put(
    constant vvc_idx : in integer;
    constant byte    : in integer
    ) is
  begin
    report "Error: Should use foreign VHPI implementation" severity failure;
  end procedure;


  function to_string(
    constant ch : t_channel
    ) return string is
  begin
    case ch is
      when NA           => return "NA";
      when ALL_CHANNELS => return "ALL_CHANNELS";
      when RX           => return "RX";
      when TX           => return "TX";
      when others =>
        report "Unknown channel type" severity failure;
        return "";
    end case;
  end function to_string;

  function to_string(
    constant status : t_transaction_status
    ) return string is
  begin
    case status is
      when INACTIVE    => return "INACTIVE";
      when IN_PROGRESS => return "IN_PROGRESS";
      when FAILED      => return "FAILED";
      when SUCCEEDED   => return "SUCCEEDED";
      when COMPLETED   => return "COMPLETED";
      when others =>
        report "Unknown transaction status type" severity failure;
        return "";
    end case;
  end function to_string;

end package body uvvm_cosim_priv_pkg;
