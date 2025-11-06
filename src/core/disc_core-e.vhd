library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;

entity disc_core_ is
    generic
    (
        W : integer := 24;
        F : integer := 18
    );
    port
    (
        clk, rst_n      : in std_ulogic;
        start_calc      : in std_ulogic;
        done            : out std_ulogic;
        a0, a1          : in signed(W-1 downto 0);
        delta_out       : out signed(W-1 downto 0);
        gamma_out       : out signed(W-1 downto 0);
        alpha0_out      : out signed(W-1 downto 0);
        mode_trig       : out std_ulogic;
        mode_degen      : out std_ulogic   
    );
end entity disc_core_;

architecture bhv of disc_core_ is

    signal a0_reg, a1_reg : signed(W-1 downto 0) := (others => '0');
    signal a0_sq_wide : signed(2*W-1 downto 0) := (others => '0');
    signal a0_sq_qf : signed(W-1 downto 0) := (others => '0');
    signal four_a1 : signed(W-1 downto 0) := (others => '0');

    signal delta_qf : signed(W-1 downto 0) := (others => '0');
    signal abs_delta : unsigned(W-1 downto 0) := (others => '0');

    signal abs_delta_shift : unsigned(F+W-1 downto 0) := (others => '0');
    signal sqrt_abs_delta_qf : unsigned(W-1 downto 0) := (others => '0');

    --FSM
    type state_type is (IDLE, MUL, REDUCE, PREP_SQRT, SQRT_RUN, POST);
    signal state : state_type := IDLE;

    function sat_signed(input : signed) return signed is
        variable result : signed(input'range) := (others => '0');
    begin
        if input'high < W-1 then
            result := resize(input, W);
        else
            if input(input'high) = '0' then
                if or_reduce(std_logic_vector(input(input'high downto W))) = '1' then
                    result := (others => '1');
                    result(W-1) := '0';
                else
                    result := resize(input, W);
                end if;
            else
                if and_reduce(std_logic_vector(not input(input'high downto W))) = '0' then
                    result := (others => '0');
                    result(W-1) := '1';
                else
                    result := resize(input, W);
                end if;

            end if;
        end if;
        return result;
    end function sat_signed;

    component isqrt_unit is
        generic (N : integer := 48);
        port
        (
            clk, rst_n : in std_ulogic;
            start      : in std_ulogic;
            din        : in unsigned(N-1 downto 0);
            dout       : out unsigned(N/2-1 downto 0);
            done       : out std_ulogic
        );
    end component isqrt_unit;

    signal sqrt_start, sqrt_done : std_ulogic := '0';
    signal sqrt_din : unsigned(F+W-1 downto 0) := (others => '0');
    signal sqrt_dout : unsigned(W-1 downto 0) := (others => '0');

begin
    done <= '1' when state = POST else '0';

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            a0_reg <= (others => '0');
            a1_reg <= (others => '0');
            a0_sq_wide <= (others => '0');
            a0_sq_qf <= (others => '0');
            four_a1 <= (others => '0');
            delta_qf <= (others => '0');
            abs_delta <= (others => '0');
            abs_delta_shift <= (others => '0');
            sqrt_start <= '0';
            sqrt_din <= (others => '0');
            sqrt_dout <= (others => '0');
            sqrt_abs_delta_qf <= (others => '0');

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start_calc = '1' then
                        a0_reg <= a0;
                        a1_reg <= a1;
                        state <= MUL;
                    end if;

                when MUL =>
                    a0_sq_wide <= resize(a0_reg, 2*W) * resize(a0_reg, 2*W);
                    four_a1 <= shift_left(resize(a1_reg, W), 2);
                    
                    state <= REDUCE;

                when REDUCE =>
                    a0_sq_qf <= sat_signed(shift_right(a0_sq_wide, F));
                    delta_qf <= sat_signed(a0_sq_qf - four_a1);
                    abs_delta <= unsigned(abs(delta_qf));
                    state <= PREP_SQRT;

                when PREP_SQRT =>
                    abs_delta_shift <= shift_left(abs_delta, F);
                    sqrt_start <= '1';
                    sqrt_din <= abs_delta_shift;
                    state <= SQRT_RUN;

                when SQRT_RUN =>
                    sqrt_start <= '0';
                    if sqrt_done = '1' then
                        sqrt_dout <= sqrt_dout;
                        sqrt_abs_delta_qf <= sqrt_dout;
                        state <= POST;
                    end if;

                when POST =>
                    state <= IDLE;
                when others =>
                    state <= IDLE;

            end case;
        end if;
    end process;
end architecture bhv;