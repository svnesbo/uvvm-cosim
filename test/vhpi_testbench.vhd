library ieee;
use ieee.std_logic_1164.all;

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

  signal a : integer := 5;
  signal b : integer := 6;
  signal y : integer;

begin

  p_test : process
  begin
    report "Starting test";

    wait for 100 ns;

    y <= vhpi_func(a, b);

    wait for 50 ns;

    report "Done. y = " & integer'image(y);

    std.env.stop; -- or std.env.finish
  end process;

end architecture sim;
