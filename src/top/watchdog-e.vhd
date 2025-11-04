library ieee;
use ieee.std_logic_1164.all;

entity watchdog is
    port (
        clk       : in  std_ulogic;
        rst_n     : in  std_ulogic;
        ui_in     : in  std_ulogic_vector(7 downto 0);
        uo_out    : out std_ulogic_vector(7 downto 0);
        uio       : in std_ulogic_vector(7 downto 0)
    );
end entity watchdog;