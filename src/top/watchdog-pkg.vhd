library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
package watchdog_pkg is

    constant W : integer := 16;
    constant I : integer := 8;

    subtype word_t is std_ulogic_vector(W-1 downto 0);
    subtype signed_t is signed(W-1 downto 0);
    subtype imag_t is std_ulogic_vector(I-1 downto 0);

end package watchdog_pkg;

package body watchdog_pkg is
end package body watchdog_pkg;