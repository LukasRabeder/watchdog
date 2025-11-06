library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;

entity eig_core is

    port
    (
        clk, rst_n      : in std_ulogic;
        start_calc      : in std_ulogic;
        a0, a1          : in word_t;
        core_busy       : out std_ulogic;
        core_done       : out std_ulogic;
        lam0_re_out     : out imag_t;
        lam0_im_out     : out imag_t;
        lam1_re_out     : out imag_t;
        lam1_im_out     : out imag_t
    );
end entity eig_core;

architecture rtl of eig_core is
    signal a0_reg, a1_reg : word_t := (others => '0');
    signal calc_start_q : std_ulogic := '0';
    signal calc_busy_q : std_ulogic := '0';
    signal calc_done_q : std_ulogic := '0';
    signal lam0_re, lam0_im, lam1_re, lam1_im : imag_t := (others => '0');
begin
    
end architecture rtl;

