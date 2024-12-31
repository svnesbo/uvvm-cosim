library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_axistream;
context bitvis_vip_axistream.vvc_context;

library work;
use work.uvvm_cosim_priv_pkg.all;

entity uvvm_cosim_axis_vvc_ctrl is
  generic (
    GC_VVC_IDX : natural);
  port (
    clk            : in std_logic;
    vvc_idx_in_use : in std_logic;
    init_done      : in std_logic);
end entity uvvm_cosim_axis_vvc_ctrl;


architecture func of uvvm_cosim_axis_vvc_ctrl is

  constant C_SCOPE : string    := "UVVM_COSIM_AXIS_VVC_CTRL";

begin

  -- Note:
  -- The GC_VVC_IS_MASTER parameter to the axistream_vvc entity is not exposed
  -- or stored anywhere, so it's not possible to know if a given axistream VVC
  -- instance is a transmitter or receiver.
  -- (Technically, maybe it can be done if we write some fancy VHPI code to
  -- search the simulation hierarchy, but that's not worth it).
  -- Instead, both transmit and receive processes are active for any axistream
  -- VVC. Which is not a problem, the user will just get an alert/error from
  -- the VVC if it tries to issue transmit to a receiver instance and vice versa.
  
  p_transmit : process
    variable v_data : std_logic_vector(7 downto 0);
  begin

    wait until init_done = '1';
    wait until rising_edge(clk);

    -- Do nothing if no VVC was registered for this index
    if vvc_idx_in_use = '0' then
      wait;
    end if;

    log(ID_SEQUENCER, "Cosim for AXISTREAM VVC " & to_string(GC_VVC_IDX) & " ENABLED.", C_SCOPE);

    loop 
      wait until rising_edge(clk);
    
      -- Schedule VVC transmit commands
      while axis_transmit_queue_empty(GC_VVC_IDX) = 0 loop
        v_data := std_logic_vector(to_unsigned(axis_transmit_queue_get(GC_VVC_IDX), v_data'length));

        log(ID_SEQUENCER, "Got byte to transmit: " & to_string(v_data, HEX), C_SCOPE);

        axistream_transmit(AXISTREAM_VVCT, GC_VVC_IDX, v_data, "Transmit from uvvm_cosim_axis_vvc_ctrl");

        if axis_transmit_queue_empty(GC_VVC_IDX) = 1 then
          log(ID_SEQUENCER, "Transmit queue now empty for VVC index " & to_string(GC_VVC_IDX), C_SCOPE);
        end if;

      end loop;
    end loop;

  end process p_transmit;


  -- This process monitors AXI-Stream VVC by repeatedly calling axistream_receive(),
  -- retrieving the data and putting it in a buffer for cosim using a foreign VHPI procedure.
  p_receive : process
    alias vvc_transaction_info_trigger : std_logic is global_axistream_vvc_transaction_trigger(GC_VVC_IDX);
    alias vvc_transaction_info         : t_transaction_group is shared_axistream_vvc_transaction_info(GC_VVC_IDX);
    variable v_cmd_idx                 : integer;
    variable v_result_data             : bitvis_vip_axistream.vvc_cmd_pkg.t_vvc_result;

    variable v_start_new_transaction   : boolean := true;

    function listen_enable (void : t_void) return boolean is
    begin
      if cosim_vvc_listen_enable("AXISTREAM_VVC", "NA", GC_VVC_IDX) then
        return true;
      else
        return false;
      end if;
    end function listen_enable;

  begin

    -- Wait at least for first clock edge before starting
    -- BFM is not configured before that...
    wait until init_done = '1';
    wait until rising_edge(clk);

    -- Do nothing if no VVC was registered for this index
    if vvc_idx_in_use = '0' then
      wait;
    end if;

    loop

      wait until rising_edge(clk);

      v_start_new_transaction := true;

      while listen_enable(void) loop

        if v_start_new_transaction then
          v_start_new_transaction := false;
          axistream_receive(AXISTREAM_VVCT, GC_VVC_IDX, TO_BUFFER, "Receive data to cosim buffer");
        end if;

        v_cmd_idx := get_last_received_cmd_idx(AXISTREAM_VVCT, GC_VVC_IDX, NA, C_SCOPE);

        wait until rising_edge(vvc_transaction_info_trigger);

        if vvc_transaction_info.bt.transaction_status = COMPLETED then

          fetch_result(AXISTREAM_VVCT, GC_VVC_IDX, v_cmd_idx, v_result_data, "Fetch received data on AXISTREAM VVC " & to_string(GC_VVC_IDX), TB_ERROR, C_SCOPE);

          if v_result_data.data_length = 0 then
            --log(ID_SEQUENCER, "AXISTREAM VVC " & to_string(GC_VVC_IDX) & " transaction timed out", C_SCOPE);
            null;
          else
            log(ID_SEQUENCER, "AXISTREAM VVC " & to_string(GC_VVC_IDX) & " transaction completed. Data: " & to_string(v_result_data.data_array(0 to v_result_data.data_length-1), HEX), C_SCOPE);

            for byte_num in 0 to v_result_data.data_length-1 loop
              axis_receive_queue_put(GC_VVC_IDX, to_integer(unsigned(v_result_data.data_array(byte_num))));
            end loop;

          end if;

          v_start_new_transaction := true;

        elsif vvc_transaction_info.bt.transaction_status = INACTIVE then
          -- Transaction is inactive - start a new one if listen is still enabled
          v_start_new_transaction := true;

        elsif vvc_transaction_info.bt.transaction_status = IN_PROGRESS then
          -- Transaction is in progress - don't do anything
          null;

        else
          -- Other transaction statuses shouldn't be relevant for the axistream VVC
          alert(TB_ERROR, "Got unexpected transaction status " & to_string(vvc_transaction_info.bt.transaction_status), C_SCOPE);
        end if;

      end loop;

    end loop;

  end process p_receive;

end architecture func;
