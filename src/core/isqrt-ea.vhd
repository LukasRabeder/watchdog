library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;
entity isqrt is
    generic
    (
        N  : integer := 48
    );
    port
    (
        clk     : in std_ulogic;
        rst_n   : in std_ulogic;
        start   : in std_ulogic;
        din     : in std_ulogic_vector(N-1 downto 0);
        dout    : out std_ulogic_vector((N+1)/2 -1 downto 0);
        done    : out std_ulogic
    );
end entity isqrt;

architecture rtl of isqrt is
    -- Number of iterations
    constant ITERS : integer := (N-1)/2;
    -- extend bits to even number, always get pairs
    constant IS_EVEN : boolean := (N mod 2 = 0);
    constant N_EVEN : integer := even_up(N); 
    -- shiftregister 
    signal x_sr : unsigned(N_EVEN-1 downto 0) := (others => '0');

    -- resut and root
    signal remain : unsigned(N_EVEN-1 downto 0) := (others => '0');
    signal root : unsigned(ITERS-1 downto 0) := (others => '0');

    type state_type is (IDLE, CALC, FIN);
    signal state : state_type := IDLE;
    signal iter_count : integer range 0 to ITERS := 0;

    signal pair_bits : unsigned(1 downto 0) := (others => '0');
    signal trial_divisor : unsigned(remain'length -1 downto 0) := (others => '0');

begin
    dout <= root;
    done <= '1' when state = FIN else '0';

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= IDLE;
            x_sr <= (others => '0');
            remain <= (others => '0');
            root <= (others => '0');
            iter_count <= 0;
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    if start = '1' then
                        x_sr <= din & (others => '0');
                        remain <= (others => '0');
                        root <= (others => '0');
                        iter_count <= 0;
                        state <= CALC;
                    end if;

                when CALC =>
                    pair_bits <= x_sr(N_EVEN-1 downto N_EVEN-2);
                    x_sr <= x_sr(N_EVEN-3 downto 0) & (others => '0');

                    trial_divisor <= (root & "1") sll (N_EVEN - 2* (iter_count + 1));

                    if remain(N_EVEN-1 downto N_EVEN-2) & pair_bits >= trial_divisor(N_EVEN-1 downto N_EVEN-2) then
                        remain <= (remain(N_EVEN-3 downto 0) & pair_bits) - trial_divisor;
                        root <= root(ITERS-2 downto 0) & '1';
                    else
                        remain <= (remain(N_EVEN-3 downto 0) & pair_bits);
                        root <= root(ITERS-2 downto 0) & '0';
                    end if;

                    if iter_count = ITERS -1 then
                        state <= FIN;
                    else
                        iter_count <= iter_count + 1;
                    end if;

                when FIN =>
                    if start = '0' then
                        state <= IDLE;
                    end if;

            end case;
        end if;
    end process;

end architecture rtl;