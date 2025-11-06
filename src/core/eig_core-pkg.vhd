library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package eig_core_pkg is

  -- Public configuration (adjust as needed)
  constant WORD_WIDTH : natural := 16;
  constant IMAG_WIDTH : natural := 16;

  subtype word_t is std_ulogic_vector(WORD_WIDTH-1 downto 0);
  subtype imag_t is std_ulogic_vector(IMAG_WIDTH-1 downto 0);

  -- Resize helpers
  function resize_s(a: signed; new_len: natural) return signed;
  function resize_u(a: unsigned; new_len: natural) return unsigned;

  -- Signed magnitude to unsigned absolute value
  function abs_to_u(a: signed) return unsigned;

  -- Core math helpers
  -- Discriminant: trace^2 - 4*det (width-safe)
  function disc(trace, det: signed) return signed;

  -- Divide by 2 (arithmetic/logical)
  function sdiv2(a: signed) return signed;
  function udiv2(a: unsigned) return unsigned;

  -- Integer square root (restoring) of an unsigned value
  function sqrt_u(x: unsigned) return unsigned;

  -- Convenience: sqrt of absolute value of a signed
  function sqrt_abs(a: signed) return unsigned;

end package eig_core_pkg;

package body eig_core_pkg is

  function resize_s(a: signed; new_len: natural) return signed is
  begin
    return resize(a, new_len);
  end function;

  function resize_u(a: unsigned; new_len: natural) return unsigned is
  begin
    return resize(a, new_len);
  end function;

  function abs_to_u(a: signed) return unsigned is
    variable tmp: signed(a'length-1 downto 0) := a;
  begin
    if a(a'high) = '1' then
      return unsigned(-tmp);
    else
      return unsigned(tmp);
    end if;
  end function;

  function sdiv2(a: signed) return signed is
  begin
    -- arithmetic right shift by 1
    return shift_right(a, 1);
  end function;

  function udiv2(a: unsigned) return unsigned is
  begin
    -- logical right shift by 1
    return shift_right(a, 1);
  end function;

  function disc(trace, det: signed) return signed is
    variable t2       : signed((trace'length*2)-1 downto 0);
    variable four_det : signed(det'length+2 downto 0);
    variable res_len  : natural := integer'max(t2'length, four_det'length) + 1;
    variable t2_r     : signed(res_len-1 downto 0);
    variable fd_r     : signed(res_len-1 downto 0);
    variable d        : signed(res_len-1 downto 0);
  begin
    t2       := trace * trace;
    four_det := shift_left(resize(det, four_det'length), 2);
    t2_r     := resize(t2, res_len);
    fd_r     := resize(four_det, res_len);
    d        := t2_r - fd_r;
    return d;
  end function;

  function sqrt_u(x: unsigned) return unsigned is
    variable rem  : unsigned(x'range) := x;
    variable root : unsigned(x'range) := (others => '0');
    variable bit  : unsigned(x'range) := (others => '0');
    variable msb_index  : integer := x'length - 1;
    variable start_index: integer;
  begin
    -- Initialize 'bit' to the largest power-of-four <= x
    if msb_index < 0 then
      return (others => '0');
    end if;
    if (msb_index mod 2) = 1 then
      start_index := msb_index;
    else
      if msb_index = 0 then
        start_index := 0;
      else
        start_index := msb_index - 1;
      end if;
    end if;
    bit(start_index) := '1';

    -- Iterative restoring square root
    while bit /= (others => '0') loop
      if rem >= (root + bit) then
        rem  := rem - (root + bit);
        root := shift_right(root, 1) + bit;
      else
        root := shift_right(root, 1);
      end if;
      bit := shift_right(bit, 2);
    end loop;

    return root;
  end function;

  function sqrt_abs(a: signed) return unsigned is
  begin
    return sqrt_u(abs_to_u(a));
  end function;

end package body eig_core_pkg;
