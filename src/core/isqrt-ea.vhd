library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cordic_sqrt is
  generic (
    IN_WIDTH  : integer := 32;
    OUT_WIDTH : integer := IN_WIDTH/2     -- 16 bei 32 Bit
  );
  port (
    clk    : in  std_ulogic;
    rst_n  : in  std_ulogic;
    start  : in  std_ulogic;
    x_in   : in  signed(IN_WIDTH-1 downto 0);
    y_out  : out unsigned(OUT_WIDTH-1 downto 0); -- floor(sqrt(|x|))
    done   : out std_ulogic;
    is_neg : out std_ulogic               -- '1' wenn x_in < 0
  );
end entity;

architecture rtl of cordic_sqrt is
  -- Zustände
  type state_t is (IDLE, RUN, FIN);
  signal st : state_t;

  -- Arbeitsregister
  signal neg_flag : std_ulogic;
  signal radicand : unsigned(IN_WIDTH-1 downto 0);     -- |x_in|
  signal shreg    : unsigned(IN_WIDTH-1 downto 0);     -- zum paarweisen Auslesen (MSB->LSB)
  signal remind      : unsigned(OUT_WIDTH*2-1 downto 0);  -- Rest-Accumulator (Breite: 2*OUT)
  signal root     : unsigned(OUT_WIDTH-1 downto 0);    -- Ergebnis wächst Bit für Bit
  signal iter     : integer range 0 to OUT_WIDTH;      -- 16 Schritte bei 32 Bit

begin
  y_out  <= root;
  done   <= '1' when st = FIN else '0';
  is_neg <= neg_flag;

  process(clk, rst_n)
    variable bring2   : unsigned(1 downto 0);
    variable trial    : unsigned(OUT_WIDTH downto 0);  -- (root<<1)|1  -> Breite OUT+1
    variable rem_next : unsigned(remind'range);
    variable root_next: unsigned(root'range);
  begin
    if rst_n = '0' then
      st       <= IDLE;
      neg_flag <= '0';
      radicand <= (others => '0');
      shreg    <= (others => '0');
      remind     <= (others => '0');
      root     <= (others => '0');
      iter     <= 0;

    elsif rising_edge(clk) then
      case st is
        when IDLE =>
          if start = '1' then
            -- Betrag bilden, Negativ-Flag setzen
            if x_in(x_in'high) = '1' then
              neg_flag <= '1';
              radicand <= (to_unsigned(0, IN_WIDTH)); -- wir rechnen 0 und flaggen
            else
              neg_flag <= '0';
              radicand <= unsigned(x_in);
            end if;

            shreg <= unsigned(x_in) when x_in(x_in'high) = '0'
                     else (others => '0');

            remind   <= (others => '0');
            root  <= (others => '0');
            iter  <= OUT_WIDTH;   -- z.B. 16
            st    <= RUN;
          end if;

        when RUN =>
          -- Nimm die beiden obersten Bits (MSB-Paar), dann shifte links (MSB->LSB Verarbeitung)
          bring2       := shreg(IN_WIDTH-1 downto IN_WIDTH-2);
          shreg        <= shreg(IN_WIDTH-3 downto 0) & "00";  -- links-Nachschub: wir haben die MSB schon "verbraucht"

          -- rem = (rem << 2) | bring_down_two_bits
          rem_next     := (remind(remind'high-2 downto 0) & bring2);

          -- trial = (root << 1) | 1
          trial        := unsigned(root & '0') + 1; -- (root<<1) + 1

          if rem_next >= resize(trial, rem_next'length) then
            -- Subtrahieren und neues Bit '1' anhängen
            remind      <= rem_next - resize(trial, rem_next'length);
            root     <= (root(root'high-1 downto 0) & '1'); -- root = (root<<1) | 1
          else
            -- Kein Abzug, neues Bit '0'
            remind      <= rem_next;
            root     <= (root(root'high-1 downto 0) & '0'); -- root = (root<<1)
          end if;

          iter <= iter - 1;
          if iter = 1 then
            st <= FIN;
          end if;

        when FIN =>
          -- ein Takt 'done', dann zurück
          st <= IDLE;
      end case;
    end if;
  end process;

end architecture;
