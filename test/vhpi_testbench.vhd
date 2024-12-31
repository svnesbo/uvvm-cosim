--hdlregression:tb
library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_uart;
context bitvis_vip_uart.vvc_context;

library bitvis_vip_axistream;
context bitvis_vip_axistream.vvc_context;

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
  signal uart0_tx : std_logic := '1';
  signal uart1_rx : std_logic;
  signal uart1_tx : std_logic := '1';

  constant C_CLK_PERIOD : time    := 20 ns;
  constant C_CLK_FREQ   : natural := 50000000;
  constant C_BAUDRATE   : natural := 1000000;

  subtype t_axistream_8b is t_axistream_if(tdata(7 downto 0),
                                           tkeep(0 downto 0),
                                           tuser(0 downto 0),
                                           tstrb(0 downto 0),
                                           tid(0 downto 0),
                                           tdest(0 downto 0)
                                           );

  signal axistream_if_transmit : t_axistream_8b;
  signal axistream_if_receive  : t_axistream_8b;

begin

  uart0_rx <= uart1_tx after 10 ns;
  uart1_rx <= uart0_tx after 10 ns;

  -- Unused AXI-Stream signals
  axistream_if_transmit.tkeep <= (others => '1');
  axistream_if_transmit.tuser <= (others => '0');
  axistream_if_transmit.tstrb <= (others => '0');
  axistream_if_transmit.tid   <= (others => '0');
  axistream_if_transmit.tdest <= (others => '0');

  axistream_if_receive.tkeep <= (others => '1');
  axistream_if_receive.tuser <= (others => '0');
  axistream_if_receive.tstrb <= (others => '0');
  axistream_if_receive.tid   <= (others => '0');
  axistream_if_receive.tdest <= (others => '0');

  axistream_if_receive.tdata   <= axistream_if_transmit.tdata;
  axistream_if_receive.tvalid  <= axistream_if_transmit.tvalid;
  axistream_if_receive.tlast   <= axistream_if_transmit.tlast;
  axistream_if_transmit.tready <= axistream_if_receive.tready;

  inst_uvvm_cosim: entity work.uvvm_cosim
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

  i_axistream_vvc0_transmit : entity bitvis_vip_axistream.axistream_vvc
    generic map (
      GC_VVC_IS_MASTER => true,
      GC_DATA_WIDTH    => 8,
      GC_USER_WIDTH    => 1,
      GC_ID_WIDTH      => 1,
      GC_DEST_WIDTH    => 1,
      GC_INSTANCE_IDX  => 0
      )
    port map (
      clk              => clk,
      axistream_vvc_if => axistream_if_transmit
      );

  i_axistream_vvc1_receive : entity bitvis_vip_axistream.axistream_vvc
    generic map (
      GC_VVC_IS_MASTER => false,
      GC_DATA_WIDTH    => 8,
      GC_USER_WIDTH    => 1,
      GC_ID_WIDTH      => 1,
      GC_DEST_WIDTH    => 1,
      GC_INSTANCE_IDX  => 1
      )
    port map (
      clk              => clk,
      axistream_vvc_if => axistream_if_receive
      );


  p_test : process
    variable v_uart_bfm_config      : t_uart_bfm_config      := C_UART_BFM_CONFIG_DEFAULT;
    variable v_axistream_bfm_config : t_axistream_bfm_config := C_AXISTREAM_BFM_CONFIG_DEFAULT;
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

    disable_log_msg(UART_VVCT, 0, RX, ALL_MESSAGES);
    disable_log_msg(UART_VVCT, 0, TX, ALL_MESSAGES);
    disable_log_msg(UART_VVCT, 1, RX, ALL_MESSAGES);
    disable_log_msg(UART_VVCT, 1, TX, ALL_MESSAGES);
    enable_log_msg(UART_VVCT, 0, RX, ID_BFM);
    enable_log_msg(UART_VVCT, 0, TX, ID_BFM);
    enable_log_msg(UART_VVCT, 1, RX, ID_BFM);
    enable_log_msg(UART_VVCT, 1, TX, ID_BFM);

    disable_log_msg(AXISTREAM_VVCT, 0, NA, ALL_MESSAGES);
    disable_log_msg(AXISTREAM_VVCT, 1, NA, ALL_MESSAGES);
    enable_log_msg(AXISTREAM_VVCT, 0, NA, ID_BFM);
    enable_log_msg(AXISTREAM_VVCT, 1, NA, ID_BFM);

    -----------------------------------------------------------------------------
    -- UART VVC config
    -----------------------------------------------------------------------------
    v_uart_bfm_config.parity                 := PARITY_NONE;
    v_uart_bfm_config.bit_time               := (1 sec) / C_BAUDRATE;
    shared_uart_vvc_config(RX, 0).bfm_config := v_uart_bfm_config;
    shared_uart_vvc_config(TX, 0).bfm_config := v_uart_bfm_config;
    shared_uart_vvc_config(RX, 1).bfm_config := v_uart_bfm_config;
    shared_uart_vvc_config(TX, 1).bfm_config := v_uart_bfm_config;

    -- Note: Default is timeout = 0 (never time out)
    shared_uart_vvc_config(RX, 1).bfm_config.timeout          := 0 ns;
    shared_uart_vvc_config(RX, 1).bfm_config.timeout_severity := NO_ALERT;

    -- Here we test with an actual timeout..
    -- Note:
    -- This does NOT work reliably because of how timeout is implemented in the BFM
    -- Use infinite timeout instead.
    --shared_uart_vvc_config(RX, 1).bfm_config.timeout          := 1000 us;
    --shared_uart_vvc_config(RX, 1).bfm_config.timeout_severity := NOTE;

    -----------------------------------------------------------------------------
    -- AXI-Stream VVC config
    -----------------------------------------------------------------------------
    v_axistream_bfm_config.check_packet_length      := false;  -- Disable tlast
    v_axistream_bfm_config.clock_period             := C_CLK_PERIOD;
    v_axistream_bfm_config.ready_default_value      := '1';
    v_axistream_bfm_config.max_wait_cycles          := 100000;
    v_axistream_bfm_config.max_wait_cycles_severity := NO_ALERT;

    shared_axistream_vvc_config(0).bfm_config := v_axistream_bfm_config;
    shared_axistream_vvc_config(1).bfm_config := v_axistream_bfm_config;

    -----------------------------------------------------------------------------
    -- Start clock
    -----------------------------------------------------------------------------
    wait for C_CLK_PERIOD;
    start_clock(CLOCK_GENERATOR_VVCT, 0, "Start clock generator");

    report "Starting test";

    wait for 100 ns;

    y <= vhpi_func(a, b);

    wait for 50 ns;

    report "Got y = " & integer'image(y) & " from foreign vhpi_func()";

    wait for 1000 ms;

    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);

    report_alert_counters(FINAL);       -- Report final counters and print conclusion for simulation (Success/Fail)

    std.env.stop; -- or std.env.finish
  end process;

end architecture sim;
