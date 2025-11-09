library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;
entity param_loader is
    port 
    (
        clk, rst_n            : in std_ulogic;
        in_pins1, in_pins2    : in std_ulogic_vector(7 downto 0);
        a0, a1                : out signed(31 downto 0);
        start_calc            : out std_ulogic;
        core_busy             : in std_ulogic
    );
end entity param_loader;

architecture rtl of param_loader is
    type state_type is (S_IDLE, S_GOT_DATA, S_CORE_BUSY);
    signal state : state_type := S_IDLE;
    signal a0_reg, a1_reg : signed(31 downto 0) := (others => '0');
    signal start_q : std_ulogic := '0';
    signal ready_q : std_ulogic := '0';
begin
    a0 <= a0_reg;
    a1 <= a1_reg;

    start_calc <= ready_q;
    start_q <= not core_busy;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= S_IDLE;
            a0_reg <= (others => '0');
            a1_reg <= (others => '0');
            start_q <= '0';
            ready_q <= '0';
        elsif rising_edge(clk) then
            start_q <= '0';
            ready_q <= '0';
            case state is
                when S_IDLE =>
                    start_q <= not core_busy;
                    
                    if start_q = '1' then
                        a0_reg <= signed('0' & in_pins1);
                        a1_reg <= signed('0' & in_pins2);
                        state <= S_GOT_DATA;
                    end if;

                when S_GOT_DATA =>
                    ready_q <= '1';
                    state <= S_CORE_BUSY;

                when S_CORE_BUSY =>
                    start_q <= not core_busy;
                    if start_q = '1' then
                        state <= S_IDLE;
                        ready_q <= '0';
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
