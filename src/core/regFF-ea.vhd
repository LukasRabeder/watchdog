library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.eig_core_pkg.all;

entity regFF_pair is
    port 
    (
        clk, rst_n : in std_ulogic;
        clk_en     : in std_ulogic;
        a0_in       : in word_t;
        a1_in       : in word_t;
        a0_out      : out word_t;
        a1_out      : out word_t
    );
end entity regFF_pair;

architecture rtl of regFF_pair is
    signal a0_reg, a1_reg : word_t := (others => '0');
    begin
        process(clk, rst_n)
        begin
            if rst_n = '0' then
                a0_reg <= (others => '0');
                a1_reg <= (others => '0');
            elsif rising_edge(clk) then
                if clk_en = '1' then
                    a0_reg <= a0_in;
                    a1_reg <= a1_in;
                end if;
            end if;
        end process;
    a0_out <= a0_reg;
    a1_out <= a1_reg;
    end architecture rtl;
