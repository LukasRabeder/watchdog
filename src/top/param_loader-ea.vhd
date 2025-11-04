library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity param_loader is
    generic ( W : integer := 16 );
    port 
    (
        clk, rst_n : in std_ulogic;
        in_data    : in std_ulogic_vector(W-1 downto 0);
        in_valid   : in std_ulogic;
        in_ready   : out std_ulogic;
        a0, a1     : out std_ulogic_vector(W-1 downto 0);
        start_calc : out std_ulogic;
        core_busy  : in std_ulogic
    );
end entity param_loader;

architecture rtl of param_loader is
    type state_type is (S_IDLE, S_GOT_A0, S_CORE_BUSY, S_PULSE_START);
    signal state : state_type := S_IDLE;
    signal a0_reg, a1_reg : std_ulogic_vector(W-1 downto 0) := (others => '0');
    signal start_q, ready_q : std_ulogic := '0';
    signal take_new_data : std_ulogic;
begin
    a0 <= a0_reg;
    a1 <= a1_reg;

    in_ready <= ready_q;
    start_calc <= start_q;
    take_new_data <= start_q and ready_q;

    process(clk, rst_n)
    begin
        if rst_n = '0' then
            state <= S_IDLE;
            a0_reg <= (others => '0');
            a1_reg <= (others => '0');
            start_q <= '0';
            ready_q <= '1';
        elsif rising_edge(clk) then
            start_q <= '0';
            case state is
                when S_IDLE =>
                    ready_q <= not core_busy;
                    
                    if take_new_data = '1' then
                        a0_reg <= in_data;
                        state <= S_GOT_A0;
                    end if;

                when S_GOT_A0 =>
                    ready_q <= '1';
                    if take_new_data = '1' then
                        a1_reg <= in_data;
                        state <= S_PULSE_START;
                        ready_q <= '0';
                    end if;

                when S_PULSE_START =>
                    start_q <= '1';
                    ready_q <= '0';
                    state <= S_CORE_BUSY;

                when S_CORE_BUSY =>
                    ready_q <= '0';
                    if core_busy = '0' then
                        state <= S_IDLE;
                        ready_q <= '1';
                    end if;
            end case;
        end if;
    end process;
end architecture rtl;
