library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_uart;
context bitvis_vip_uart.vvc_context;

library bitvis_vip_axistream;
context bitvis_vip_axistream.vvc_context;

library work;
use work.uvvm_cosim_priv_pkg.all;

entity uvvm_cosim_sched is
  generic (
    GC_SIM_RUN_CTRL_EN : boolean := false);
  port (
    clk : in std_logic);
end entity uvvm_cosim_sched;


architecture func of uvvm_cosim_sched is

  constant C_SCOPE : string    := "UVVM_COSIM_SCHED";
  signal init_done : std_logic := '0';

begin

  p_uvvm_init : process
  begin
    loop
      wait for 0 ns;
      exit when shared_uvvm_state = INIT_COMPLETED;
    end loop;

    log(ID_SEQUENCER, "UVVM initialization complete!", C_SCOPE);

    if GC_SIM_RUN_CTRL_EN then
      log(ID_SEQUENCER, "Waiting to start simulation", C_SCOPE);

      uvvm_cosim_vhpi_start_sim; -- Blocks until user says sim should start

      log(ID_SEQUENCER, "Starting simulation", C_SCOPE);
    end if;

    -- Report VVC info
    for idx in 0 to shared_vvc_activity_register.priv_get_num_registered_vvcs(VOID)-1 loop

      uvvm_cosim_vhpi_report_vvc_info(
        shared_vvc_activity_register.priv_get_vvc_name(idx),
        to_string(shared_vvc_activity_register.priv_get_vvc_channel(idx)),
        shared_vvc_activity_register.priv_get_vvc_instance(idx)
      );

    end loop;

    init_done <= '1';

    wait;
  end process p_uvvm_init;

  p_sched : process
    variable data : std_logic_vector(7 downto 0);
  begin

    wait until rising_edge(clk);

    -- Schedule VVC commands
    while uart_transmit_queue_empty = 0 loop
      data := std_logic_vector(to_unsigned(uart_transmit_queue_get, data'length));

      log(ID_SEQUENCER, "Got uart transmit byte: " & to_string(data, HEX), C_SCOPE);

      uart_transmit(UART_VVCT, 0, TX, data, "Transmit from uvvm_cosim_sched");

      if uart_transmit_queue_empty = 1 then
        log(ID_SEQUENCER, "UART transmit queue now empty", C_SCOPE);
      end if;

    end loop;

  end process p_sched;


  -- This process monitors UART Rx VVC by repeatedly calling uart_receive(),
  -- retrieving the data and putting it in a buffer for cosim using a foreign VHPI procedure.
  p_monitor : process
    -- Hard-coded alias for Rx channel on UART VVC index 1
    alias vvc_transaction_info_trigger : std_logic is global_uart_vvc_transaction_trigger(RX, 1);
    alias vvc_transaction_info         : bitvis_vip_uart.transaction_pkg.t_transaction_group is shared_uart_vvc_transaction_info(RX, 1);
    variable v_cmd_idx                 : integer;
    variable v_result_data             : bitvis_vip_uart.vvc_cmd_pkg.t_vvc_result;
  begin

    wait until init_done = '1';

    -- Wait for first clock edge before starting
    -- BFM is not configured before that...
    wait until rising_edge(clk);

    -- Note:
    -- BFM config should be configured with:
    -- * inter_bfm_delay = 0 (no delay between BFM access)
    -- * long/infinite timeout? Maybe unnecessary if inter_bfm_delay = 0 and
    -- We re-trigger immediately on timeout
    -- * timeout_severity = NO_ALERT (or something similar)

    uart_receive(UART_VVCT, 1, RX, TO_BUFFER, "Receive data to cosim buffer");

    loop

      v_cmd_idx := get_last_received_cmd_idx(UART_VVCT, 1, Rx, C_SCOPE);

      wait until rising_edge(vvc_transaction_info_trigger);

      if vvc_transaction_info.bt.transaction_status = COMPLETED then
        if vvc_transaction_info.bt.data = x"XX" then
          -- Transaction timed out - don't do anything, we'll retrigger receive
          -- below.

          -- The original idea was that this could support a finite timeout
          -- configured for the BFM (the default is zero, which is infinite
          -- timeout).
          -- However, THIS DOES NOT work reliably because of how timeout is
          -- implemented in the UART BFM, because it:
          -- 1) Wait for start bit edge OR timeout
          -- 2) The BFM still checks for timeout after it gets the start bit edge
          -- * So, if it gets the start bit edge with insufficient time left,
          --   it will start receiving and timeout during the transfer. At this
          --   point it's too late to restart since we are in the middle of the
          --   transfer.
          -- * Had the BFM always allowed a full byte to be received as long as the
          --   start bit was received within the timeout, then it would have
          --   been possible to re-trigger receive on timeout. But with the
          --   current implementation that is impossible.
          null;
        else
          log(ID_SEQUENCER, "UART Rx VVC 1 transaction completed. Data: " & to_string(vvc_transaction_info.bt.data, HEX), C_SCOPE);

          uart_receive_queue_put(to_integer(unsigned(vvc_transaction_info.bt.data)));
        end if;

        -- The fetched result basically returns EXACTLY the same data as what's
        -- available in transaction_info.
        -- There is no additional info in the fetch result (eg. if the command
        -- timed out). So it is kinda useless to fetch this, BUT, we HAVE to do
        -- it because otherwise the result queue will overflow at some point
        -- (1000 elements by default) which causes a fatal alert.
        fetch_result(UART_VVCT, 1, RX, v_cmd_idx, v_result_data, "Fetch received data on UART 1 RX.", TB_ERROR, C_SCOPE);

        uart_receive(UART_VVCT, 1, RX, TO_BUFFER, "Receive data to cosim buffer");

      elsif vvc_transaction_info.bt.transaction_status = INACTIVE then
        -- Transaction is inactive - start a new one
        uart_receive(UART_VVCT, 1, RX, TO_BUFFER, "Receive data to cosim buffer");

      elsif vvc_transaction_info.bt.transaction_status = IN_PROGRESS then
        -- Transaction is in progress - don't do anything
        null;

      elsif vvc_transaction_info.bt.transaction_status = SUCCEEDED then
        alert(TB_ERROR, "Got unexpected transaction status SUCCEEDED (which is used for monitor, not VVC)", C_SCOPE);
      elsif vvc_transaction_info.bt.transaction_status = FAILED then
        alert(TB_ERROR, "Got unexpected transaction status FAILED (which is used for monitor, not VVC)", C_SCOPE);
      end if;

    end loop;

  end process p_monitor;


  p_sched_axistream : process
    variable data : std_logic_vector(7 downto 0);
  begin

    wait until rising_edge(clk);

    -- Schedule VVC commands
    while axis_transmit_queue_empty = 0 loop
      data := std_logic_vector(to_unsigned(axis_transmit_queue_get, data'length));

      log(ID_SEQUENCER, "Got axistream transmit byte: " & to_string(data, HEX), C_SCOPE);

      axistream_transmit(AXISTREAM_VVCT, 0, data, "Transmit from uvvm_cosim_sched");

      if axis_transmit_queue_empty = 1 then
        log(ID_SEQUENCER, "AXISTREAM transmit queue now empty", C_SCOPE);
      end if;

    end loop;

  end process p_sched_axistream;


  -- This process monitors AXI-Stream VVC by repeatedly calling axistream_receive(),
  -- retrieving the data and putting it in a buffer for cosim using a foreign VHPI procedure.
  p_monitor_axistream : process
    -- Hard-coded alias for AXI-Stream VVC index 1 (used for receive)
    alias vvc_transaction_info_trigger : std_logic is global_axistream_vvc_transaction_trigger(1);
    alias vvc_transaction_info         : bitvis_vip_axistream.transaction_pkg.t_transaction_group is shared_axistream_vvc_transaction_info(1);
    variable v_cmd_idx                 : integer;
    variable v_result_data             : bitvis_vip_axistream.vvc_cmd_pkg.t_vvc_result;

  begin

    wait until init_done = '1';

    -- Wait for first clock edge before starting
    -- BFM is not configured before that...
    wait until rising_edge(clk);

    axistream_receive(AXISTREAM_VVCT, 1, TO_BUFFER, "Receive data to cosim buffer");

    loop

      v_cmd_idx := get_last_received_cmd_idx(AXISTREAM_VVCT, 1, NA, C_SCOPE);

      wait until rising_edge(vvc_transaction_info_trigger);

      if vvc_transaction_info.bt.transaction_status = COMPLETED then

        fetch_result(AXISTREAM_VVCT, 1, v_cmd_idx, v_result_data, "Fetch received data on AXISTREAM VVC 1.", TB_ERROR, C_SCOPE);

        if v_result_data.data_length = 0 then
          --log(ID_SEQUENCER, "AXISTREAM VVC 1 transaction timed out", C_SCOPE);
          null;
        else
          log(ID_SEQUENCER, "AXISTREAM VVC 1 transaction completed. Data: " & to_string(v_result_data.data_array(0 to v_result_data.data_length-1), HEX), C_SCOPE);

          for byte_num in 0 to v_result_data.data_length-1 loop
            axis_receive_queue_put(to_integer(unsigned(v_result_data.data_array(byte_num))));
          end loop;

        end if;

        -- Start new receive transaction
        axistream_receive(AXISTREAM_VVCT, 1, TO_BUFFER, "Receive data to cosim buffer");

      elsif vvc_transaction_info.bt.transaction_status = INACTIVE then
        -- Transaction is inactive - start a new one
        axistream_receive(AXISTREAM_VVCT, 1, TO_BUFFER, "Receive data to cosim buffer");

      elsif vvc_transaction_info.bt.transaction_status = IN_PROGRESS then
        -- Transaction is in progress - don't do anything
        null;

      else
        -- Other transaction statuses shouldn't be relevant for the axistream VVC
        alert(TB_ERROR, "Got unexpected transaction status " & to_string(vvc_transaction_info.bt.transaction_status), C_SCOPE);
      end if;

    end loop;

  end process p_monitor_axistream;

end architecture func;
