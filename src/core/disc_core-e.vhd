library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;

entity disc_core_ is
    generic
    (
        W : integer := 32; -- word length
        F : integer := 16  -- fractional bits
    );
    port
    (
        clk, rst_n      : in std_logic;
        start_calc      : in std_logic;
        done            : out std_logic;
        a0, a1          : in signed(W-1 downto 0);

        disc            : out signed(W-1 downto 0)
    );
end entity disc_core_;
