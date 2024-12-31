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

entity uvvm_cosim is
  generic (
    GC_SIM_RUN_CTRL_EN : boolean := false);
  port (
    clk : in std_logic);
end entity uvvm_cosim;


architecture func of uvvm_cosim is

  constant C_SCOPE : string    := "UVVM_COSIM";
  signal init_done : std_logic := '0';

  signal uart_rx_vvc_indexes_in_use : std_logic_vector(0 to C_UART_VVC_MAX_INSTANCE_NUM-1)      := (others => '0');
  signal uart_tx_vvc_indexes_in_use : std_logic_vector(0 to C_UART_VVC_MAX_INSTANCE_NUM-1)      := (others => '0');
  signal axis_vvc_indexes_in_use    : std_logic_vector(0 to C_AXISTREAM_VVC_MAX_INSTANCE_NUM-1) := (others => '0');

  impure function strcmp (
    constant str1 : string;
    constant str2 : string)
    return boolean is
  begin
    assert str1'length <= str2'length report "str1 can't be longer than str2" severity failure;

    if str1(1 to str1'length) = str2(1 to str1'length) then
      return true;
    else
      return false;
    end if;
  end function strcmp;

begin

  p_uvvm_cosim_init : process
    variable vvc_channel     : t_channel;
    variable vvc_instance_id : integer;
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

    -- Check which VVCs were registered in this testbench
    for idx in 0 to shared_vvc_activity_register.priv_get_num_registered_vvcs(VOID)-1 loop

      vvc_channel     := shared_vvc_activity_register.priv_get_vvc_channel(idx);
      vvc_instance_id := shared_vvc_activity_register.priv_get_vvc_instance(idx);

      -- Report VVC info to cosim server via VHPI
      uvvm_cosim_vhpi_report_vvc_info(
        shared_vvc_activity_register.priv_get_vvc_name(idx),
        to_string(vvc_channel),
        vvc_instance_id
        );

      -- Note:
      -- Can't compare strings directly with = because that compares the full
      -- range of the string. The string returned from priv_get_vvc_name always
      -- has range 1 to 20 (probably a fixed size for VVC type name in UVVM),
      -- while the literal has whatever size is needed to hold the characters.
      if strcmp("UART_VVC", shared_vvc_activity_register.priv_get_vvc_name(idx)) then

        if vvc_channel = TX then
          uart_tx_vvc_indexes_in_use(vvc_instance_id) <= '1';
        elsif vvc_channel = RX then
          uart_rx_vvc_indexes_in_use(vvc_instance_id) <= '1';
        end if;

      elsif strcmp("AXISTREAM_VVC", shared_vvc_activity_register.priv_get_vvc_name(idx)) then
        axis_vvc_indexes_in_use(vvc_instance_id) <= '1';
      end if;

    end loop;

    init_done <= '1';

    wait;
  end process p_uvvm_cosim_init;

  g_uart_vvc_ctrl: for vvc_idx in 0 to C_UART_VVC_MAX_INSTANCE_NUM-1 generate

    inst_uart_vvc_ctrl : entity work.uvvm_cosim_uart_vvc_ctrl
      generic map (
        GC_VVC_IDX => vvc_idx)
      port map (
        clk               => clk,
        tx_vvc_idx_in_use => uart_tx_vvc_indexes_in_use(vvc_idx),
        rx_vvc_idx_in_use => uart_rx_vvc_indexes_in_use(vvc_idx),
        init_done         => init_done);

  end generate g_uart_vvc_ctrl;

  g_axis_vvc_ctrl: for vvc_idx in 0 to C_AXISTREAM_VVC_MAX_INSTANCE_NUM-1 generate

    inst_axis_vvc_ctrl: entity work.uvvm_cosim_axis_vvc_ctrl
      generic map (
        GC_VVC_IDX => vvc_idx)
      port map (
        clk            => clk,
        vvc_idx_in_use => axis_vvc_indexes_in_use(vvc_idx),
        init_done      => init_done);

  end generate g_axis_vvc_ctrl;

end architecture func;
