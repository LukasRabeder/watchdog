library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.eig_core_pkg.all;

entity output_loader is
    port
    (
        clk, rst_n  : in std_ulogic;
        core_done   : in std_ulogic;
        lam0_re_in     : in imag_t;
        lam0_im_in     : in imag_t;
        lam1_re_in     : in imag_t;
        lam1_im_in     : in imag_t;

        out_ready   : in std_ulogic;
        out_data    : out imag_t;
        out_valid   : out std_ulogic;

        core_busy_out : out std_ulogic
    );
end entity output_loader;

architecture rtl of output_loader is
    type state_type is (WAIT_CORE, SEND_LAM0_RE, SEND_LAM0_IM, SEND_LAM1_RE, SEND_LAM1_IM);
    signal state : state_type := WAIT_CORE;

    signal lam0_re, lam0_im, lam1_re, lam1_im : imag_t := (others => '0');

    signal data_q : imag_t := (others => '0');
    signal valid_q : std_ulogic := '0';
    signal busy_q : std_ulogic := '0';
begin
    out_data <= data_q;
    out_valid <= valid_q;
    core_busy_out <= busy_q;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= WAIT_CORE;
            data_q <= (others => '0');
            valid_q <= '0';
            busy_q <= '0';
            lam0_re <= (others => '0');
            lam0_im <= (others => '0');
            lam1_re <= (others => '0');
            lam1_im <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when WAIT_CORE =>
                    valid_q <= '0';
                    busy_q <= '0';
                    if core_done = '1' then
                        lam0_re <= lam0_re_in;
                        lam0_im <= lam0_im_in;
                        lam1_re <= lam1_re_in;
                        lam1_im <= lam1_im_in;

                        state <= SEND_LAM0_RE;
                        valid_q <= '1';
                        busy_q <= '1';
                    end if;

                when SEND_LAM0_RE =>
                    valid_q <= '1';
                    if out_ready = '1' then
                        data_q <= lam0_re;
                        state <= SEND_LAM0_IM;
                    end if;

                when SEND_LAM0_IM =>
                    valid_q <= '1';
                    if out_ready = '1' then
                        data_q <= lam0_im;
                        state <= SEND_LAM1_RE;
                    end if;

                when SEND_LAM1_RE =>
                    valid_q <= '1';
                    if out_ready = '1' then
                        data_q <= lam1_re;
                        state <= SEND_LAM1_IM;
                    end if;

                when SEND_LAM1_IM =>
                    valid_q <= '1';
                    if out_ready = '1' then
                        data_q <= lam1_im;
                        state <= WAIT_CORE;
                        valid_q <= '0';
                        busy_q <= '0';
                    end if;

            end case;
        end if;
    end process;
end architecture rtl;
