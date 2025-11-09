library ieee;
use ieee.std_logic_1164.all;

entity watchdog is
    port (
        clk       : in  std_logic;
        rst_n     : in  std_logic;
        ui_in     : in  std_logic_vector(7 downto 0);
        uo_out    : out std_logic_vector(7 downto 0);
        uio       : in std_logic_vector(7 downto 0)
    );
end entity watchdog;