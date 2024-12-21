--hdlregression:tb
library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_uart;
context bitvis_vip_uart.vvc_context;

library bitvis_vip_clock_generator;
context bitvis_vip_clock_generator.vvc_context;

entity tb is
end entity tb;

architecture sim of tb is

  function vhpi_func (a : integer;
                      b : integer)
    return integer is
  begin
    report "Ooops" severity failure;
  end function;

  attribute foreign of vhpi_func : function is "VHPI vhpi_lib vhpi_func";

  signal clk : std_logic;
  signal a   : integer := 5;
  signal b   : integer := 6;
  signal y   : integer;

  signal uart0_rx : std_logic;
  signal uart0_tx : std_logic;
  signal uart1_rx : std_logic;
  signal uart1_tx : std_logic;

  constant C_CLK_PERIOD : time    := 20 ns;
  constant C_CLK_FREQ   : natural := 50000000;
  constant C_BAUDRATE   : natural := 115200;

begin

  uart0_rx <= uart1_tx;
  uart1_rx <= uart0_tx;

  inst_uvvm_cosim_sched: entity work.uvvm_cosim_sched
    generic map (
      GC_SIM_RUN_CTRL_EN => true)
    port map (
      clk => clk);

  inst_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

  inst_clk_vvc : entity bitvis_vip_clock_generator.clock_generator_vvc
    generic map (
      GC_INSTANCE_IDX    => 0,
      GC_CLOCK_NAME      => "Clock",
      GC_CLOCK_PERIOD    => C_CLK_PERIOD,
      GC_CLOCK_HIGH_TIME => C_CLK_PERIOD/2
      )
    port map (
      clk => clk
      );

  inst_uart0_vvc : entity bitvis_vip_uart.uart_vvc
    generic map (
      GC_DATA_WIDTH   => 8,
      GC_INSTANCE_IDX => 0)
    port map (
      uart_vvc_rx => uart0_rx,
      uart_vvc_tx => uart0_tx);

  inst_uart1_vvc : entity bitvis_vip_uart.uart_vvc
    generic map (
      GC_DATA_WIDTH   => 8,
      GC_INSTANCE_IDX => 1)
    port map (
      uart_vvc_rx => uart1_rx,
      uart_vvc_tx => uart1_tx);


  p_test : process
    variable v_uart_bfm_config : t_uart_bfm_config := C_UART_BFM_CONFIG_DEFAULT;
  begin
    -----------------------------------------------------------------------------
    -- Wait for UVVM to finish initialization
    -----------------------------------------------------------------------------
    await_uvvm_initialization(VOID);

    -----------------------------------------------------------------------------
    -- Set UVVM verbosity level
    -----------------------------------------------------------------------------
    disable_log_msg(ALL_MESSAGES);
    enable_log_msg(ID_SEQUENCER);
    enable_log_msg(ID_LOG_HDR);
    enable_log_msg(ID_VVC_ACTIVITY);


    -----------------------------------------------------------------------------
    -- UART VVC config
    -----------------------------------------------------------------------------
    v_uart_bfm_config.parity                 := PARITY_NONE;
    v_uart_bfm_config.bit_time               := (1 sec) / 115200;
    shared_uart_vvc_config(RX, 0).bfm_config := v_uart_bfm_config;
    shared_uart_vvc_config(TX, 0).bfm_config := v_uart_bfm_config;
    shared_uart_vvc_config(RX, 1).bfm_config := v_uart_bfm_config;
    shared_uart_vvc_config(TX, 1).bfm_config := v_uart_bfm_config;

    report "Starting test";

    wait for 100 ns;

    y <= vhpi_func(a, b);

    wait for 50 ns;

    report "Done. y = " & integer'image(y);

    std.env.stop; -- or std.env.finish
  end process;

end architecture sim;
