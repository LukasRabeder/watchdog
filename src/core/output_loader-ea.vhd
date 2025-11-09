library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.eig_core_pkg.all;

entity output_loader is
    generic 
    (
        W : integer := 32
    );
    port
    (
        clk                : in std_logic;
        rst_n              : in std_logic;

        -- Handshake
        start              : in std_logic;
        mode               : in std_logic_vector(2 downto 0);

        wordA              : in std_logic_vector(W-1 downto 0); -- inv(\Kau)
        wordB              : in std_logic_vector(W-1 downto 0); -- \Kau

        -- status
        busy               : out std_logic;
        -- Serialized 8-bit output
        out_byte           : out std_logic_vector(7 downto 0)
    );

end entity output_loader;

architecture rtl of output_loader is
    type state_t is (IDLE, SEND_A, SEND_B);
    signal state : state_t := IDLE;

    signal shift_reg  : std_logic_vector(W-1 downto 0);
    signal nibble_idx : integer range 0 to 7 := 0; -- 8 nibbles per word
    signal cur_mode   : std_logic_vector(2 downto 0) := (others=>'0');
    signal data_rdy   : std_logic := '0';
begin
    busy <= '1' when state /= IDLE else '0';

    process(clk, rst_n)
        variable nibble : std_logic_vector(3 downto 0);
    begin
        if rst_n = '0' then
            state <= IDLE;
            nibble_idx <= 0;
            cur_mode <= (others=>'0');
            data_rdy <= '0';
            out_byte <= (others=>'0');
            shift_reg <= (others=>'0');
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    data_rdy <= '0';
                    if start = '1' then
                        cur_mode <= mode;
                        shift_reg <= wordA;
                        nibble_idx <= 7;
                        data_rdy <= '1'; 
                        state <= SEND_A;
                    end if;
                when SEND_A =>
                    nibble := sel_nibble32(shift_reg, nibble_idx);
                    out_byte <= cur_mode & '1' & nibble; -- [7:5]mode [4]rdy [3:0]nibble
                    if nibble_idx = 0 then
                        shift_reg <= wordB;
                        nibble_idx <= 7;
                        state <= SEND_B;
                    else
                        nibble_idx <= nibble_idx -1;
                    end if;
                when SEND_B =>
                    nibble := sel_nibble32(shift_reg, nibble_idx);
                    out_byte <= cur_mode & '1' & nibble;
                    if nibble_idx = 0 then
                        data_rdy <= '0';
                        out_byte <= (others=>'0');
                        state <= IDLE;
                    else
                        nibble_idx <= nibble_idx -1;
                    end if;
                end case;
            end if;
        end process;
end architecture rtl;