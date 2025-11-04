library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.watchdog_pkg.all;

architecture rtl of watchdog is
    signal clk_i       : std_ulogic;
    signal rst_n_i     : std_ulogic;
    signal ui_in_i     : std_ulogic_vector(7 downto 0);
    signal uio_i     : std_ulogic_vector(7 downto 0);
    signal uo_out_i    : std_ulogic_vector(7 downto 0);

    begin
clk_i    <= clk;
rst_n_i  <= rst_n;
ui_in_i  <= ui_in;
uio_i    <= uio;

uo_out_i <= (others => '0');
uo_out    <= uo_out_i;

end architecture rtl;