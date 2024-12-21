library ieee;
use ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library work;
use work.uvvm_cosim_priv_pkg.all;

entity uvvm_cosim_sched is
  generic (
    GC_SIM_RUN_CTRL_EN : boolean := true);
  port (
    clk : in std_logic);
end entity uvvm_cosim_sched;


architecture func of uvvm_cosim_sched is

  constant C_SCOPE    : string  := "UVVM_COSIM_SCHED";

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

    wait;
  end process p_uvvm_init;

  p_sched : process(clk)
  begin
    if rising_edge(clk) then
      -- Schedule VVC commands
    end if;
  end process p_sched;

end architecture func;
