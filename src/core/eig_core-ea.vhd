library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;

entity eig_core is

    port
    (
        clk, rst_n      : in std_logic;
        data_rdy        : in std_logic;
        a0, a1          : in signed(31 downto 0);
        core_busy       : out std_logic;
        omega           : out signed(31 downto 0);
        kappa           : out signed(31 downto 0);
        neg_beta_h      : out signed(31 downto 0);
        sqrt_disc_half  : out signed(31 downto 0);
        regime          : out std_logic_vector(2 downto 0) --100: overdamoed, 010: critical, 001:underdamped
    );
end entity eig_core;

architecture rtl of eig_core is
    signal alpha, beta : signed(31 downto 0) := (others => '0');
    signal start_calc : std_ulogic := '0';
    signal disc_neg : std_logic := '0';
    signal sqrt_done : std_logic := '0';
    signal disc_rdy : std_logic := '0';
    
    signal calc_done_q : std_logic := '0';
    signal regime_q : std_logic_vector(2 downto 0) := (others => '0');
    signal alpha4, beta_sq, disc_q : signed(63 downto 0) := (others => '0');
    signal alpha_q, beta_q, omega_q, kappa_q, neg_beta_h_q, sqrt_disc_half_q : signed(31 downto 0) := (others => '0');

    type state_type is (IDLE, PREP_DISC, CALC_DISC, DONE);
    signal state : state_type := IDLE;
begin
        sqrt_instance : entity work.cordic_sqrt
        generic map (
            IN_WIDTH  => 64,
            OUT_WIDTH => 32
        )
        port map (
            clk    => clk,
            rst_n  => rst_n,
            start  => disc_rdy,
            x_in   => signed(disc_q),
            y_out  => unsigned(sqrt_disc_half_q),
            done   => sqrt_done,
            is_neg => disc_neg
        );
    core_busy <= not calc_done_q;
    regime <= regime_q;
    neg_beta_h <= neg_beta_h_q;
    omega <= omega_q;
    kappa <= kappa_q;
    sqrt_disc_half <= sqrt_disc_half_q;
    process(clk, rst_n)
    begin 
        if rst_n = '0' then
            state <= IDLE;
            calc_done_q <= '0';
            start_calc <= '0';
            regime_q <= (others => '0');
            alpha_q <= (others => '0');
            beta_q <= (others => '0');
            omega_q <= (others => '0');
            kappa_q <= (others => '0');
            neg_beta_h_q <= (others => '0');
            sqrt_disc_half_q <= (others => '0');
            disc_neg <= '0';
            sqrt_done <= '0';
            disc_rdy <= '0';
        elsif rising_edge(clk) then
            start_calc <= data_rdy;
            if state = IDLE then
                if data_rdy = '1' then
                    alpha <= a0;
                    beta <= a1;
                    state <= PREP_DISC;
                end if;
            elsif state = PREP_DISC then
                alpha4 <= shift_left(alpha, 2); -- alpha *4
                beta_sq <= signed(resize(unsigned(beta) * unsigned(beta), 64));
                if alpha4 < beta_sq then
                    regime_q <= "100"; -- overdamped
                    disc_q <= alpha4 - beta_sq;
                elsif alpha4 = beta_sq then
                    regime_q <= "010"; -- critical
                    disc_q <= (others => '0');
                else
                    regime_q <= "001"; -- underdamped
                    disc_q <= beta_sq - alpha4;
                end if;
                state <= CALC_DISC;
            elsif state = CALC_DISC then
                disc_rdy <= '1';
                if sqrt_done = '1' then
                    disc_rdy <= '0';
                    sqrt_disc_half_q <= shift_right(sqrt_disc_half_q, 1); -- sqrt(disc)/2
                    neg_beta_h_q <= shift_right(-beta, 1); -- -beta/2
                end if;
            end if; 
        end if;
    end process;
end architecture rtl;

