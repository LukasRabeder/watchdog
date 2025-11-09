library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity inv_recip is
  generic(
    W : integer := 32; -- word length
    F : integer := 16  -- fractional bits (QF)
  );
  port(
    clk, rst_n : in  std_logic;
    start_calc : in  std_logic;
    done       : out std_logic;
    x_in       : in  signed(W-1 downto 0);   -- QF, erwartet x>0
    x_inv      : out unsigned(W-1 downto 0); -- QF, approx 1/x_in
    invalid    : out std_logic              -- '1' wenn x<=0
  );
end;

architecture rtl of inv_recip is
  -- 16-Entry LUT (QF) für Startwert (rough 1/x in [0.5,1))
  type lut_type is array (0 to 15) of unsigned(W-1 downto 0);
  constant inv_lut : lut_type := (
    to_unsigned( 65536, W), -- 1.0000 Q16
    to_unsigned( 61440, W), -- 0.9375
    to_unsigned( 57344, W), -- 0.8750
    to_unsigned( 53248, W), -- 0.8125
    to_unsigned( 49152, W), -- 0.7500
    to_unsigned( 45056, W), -- 0.6875
    to_unsigned( 40960, W), -- 0.6250
    to_unsigned( 36864, W), -- 0.5625
    to_unsigned( 32768, W), -- 0.5000
    to_unsigned( 28672, W), -- 0.4375
    to_unsigned( 24576, W), -- 0.3750
    to_unsigned( 20480, W), -- 0.3125
    to_unsigned( 16384, W), -- 0.2500
    to_unsigned( 12288, W), -- 0.1875
    to_unsigned(  8192, W), -- 0.1250
    to_unsigned(  4096, W)  -- 0.0625
  );

  type st_t is (S_IDLE, S_CHECK, S_NORM, S_LUT, S_IT0, S_IT1, S_IT2, S_IT3, S_DEN, S_DONE);
  signal st : st_t := S_IDLE;

  signal x_abs   : unsigned(W-1 downto 0);
  signal x_norm  : unsigned(W-1 downto 0);  -- QF, in [0.5,1)
  signal e       : integer range -W to W := 0;

  signal y       : unsigned(W-1 downto 0);  -- QF, iterierender Kehrwert
  signal idx     : integer range 0 to 15 := 0;

  -- breite Mul für QF*QF
  constant M : integer := 2*W;
  signal xy  : unsigned(M-1 downto 0);
  signal yc  : unsigned(M-1 downto 0);

  function msb_pos(u : unsigned) return integer is
  begin
    for i in u'range loop
      if u(u'high - i) = '1' then
        return u'high - i; -- 0-basiert von LSB
      end if;
    end loop;
    return 0;
  end function;

begin
  invalid <= '1' when (st = S_DONE and (x_in <= 0)) else '0';
  done    <= '1' when (st = S_DONE) else '0';
  x_inv   <= y;

  process(clk, rst_n)
    variable p  : integer;
    variable s  : integer;
    variable tmpQF : unsigned(W-1 downto 0);
    constant TWO_QF : unsigned(W-1 downto 0) := to_unsigned(2**(F+1), W); -- 2.0 in QF
  begin
    if rst_n = '0' then
      st <= S_IDLE;
      x_abs <= (others => '0');
      x_norm<= (others => '0');
      e     <= 0;
      y     <= (others => '0');
      idx   <= 0;
    elsif rising_edge(clk) then
      case st is
        when S_IDLE =>
          if start_calc = '1' then
            st    <= S_CHECK;
          end if;

        when S_CHECK =>
          if x_in <= 0 then
            y  <= (others => '0');
            st <= S_DONE;
          else
            x_abs <= unsigned(x_in); -- nur positive Domain
            st    <= S_NORM;
          end if;

        when S_NORM =>
          if x_abs = 0 then
            y  <= (others => '0'); st <= S_DONE;
          else
            p := msb_pos(x_abs);         -- Position des MSB (0..W-1)
            s := (F-1) - p;              -- Shift, um MSB auf Bit F-1 zu bringen
            if s >= 0 then
              x_norm <= shift_left(x_abs, s);
            else
              x_norm <= shift_right(x_abs, -s);
            end if;
            e <= -s;                     -- x = x_norm * 2^e
            st <= S_LUT;
          end if;

        when S_LUT =>
          idx <= to_integer(x_norm(W-1 downto W-4));        -- oberes Nibble
          y   <= inv_lut(to_integer(x_norm(W-1 downto W-4)));
          st  <= S_IT0;

        -- Iteration: y = y * (2 - x_norm*y)
        -- Alle Größen sind QF
        when S_IT0 | S_IT1 | S_IT2 | S_IT3 =>
          xy <= resize(x_norm, M) * resize(y, M);           -- QF*QF
          -- (x*y)>>F  -> wieder QF
          tmpQF := resize( shift_right(xy, F)(W-1 downto 0), W);
          -- corr = 2 - x*y
          yc <= resize(y, M) * resize(TWO_QF - tmpQF, M);   -- QF*QF
          y  <= resize( shift_right(yc, F)(W-1 downto 0), W); -- zurück nach QF
          case st is
            when S_IT0 => st <= S_IT1;
            when S_IT1 => st <= S_IT2;
            when S_IT2 => st <= S_IT3;
            when others=> st <= S_DEN;
          end case;

        when S_DEN =>
          -- 1/x = (1/x_norm) * 2^{-e}
          if e > 0 then
            y <= shift_right(y, e);   -- 2^{-e} mit e>0 => >> e
          elsif e < 0 then
            y <= shift_left(y, -e);   -- 2^{-e} mit e<0 => << (-e)
          end if;
          st <= S_DONE;

        when S_DONE =>
          st <= S_IDLE;
      end case;
    end if;
  end process;
end architecture;
