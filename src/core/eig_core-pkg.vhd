library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package eig_core_pkg is
    -- datatypes
    subtype word_t  is std_ulogic_vector(15 downto 0);  -- 16 Bit Wort
    subtype signed_t is signed(15 downto 0);            -- 16 Bit signed
    subtype frac_t  is signed(23 downto 0);             -- 24 Bit Fractional
    subtype imag_t  is std_ulogic_vector(7 downto 0);   -- 8 Bit Imaginary Output

    function frac_to_word(x : frac_t) return word_t;
    function word_to_frac(v : word_t) return frac_t;

    function or_reduce(v : std_ulogic_vector) return std_ulogic;
    function and_reduce(v : std_ulogic_vector) return std_ulogic;

    function even_up(x : integer) return integer;

end package eig_core_pkg;

package body eig_core_pkg is

    function frac_to_word(x : frac_t) return word_t is
        variable resized : signed(15 downto 0);
        begin
            resized := resize(x, 16);
            return std_ulogic_vector(resized);
        end function frac_to_word;

    function word_to_frac(v : word_t) return frac_t is
        variable signed_v : signed(15 downto 0);
        variable result : frac_t;
        begin 
            signed_v := signed(v);
            result := resize(signed_v, 24);
            return result;
        end function word_to_frac;

        function or_reduce(v : std_ulogic_vector) return std_ulogic is
        variable result : std_ulogic := '0';
        begin
            for i in v'range loop
                if v(i) = '1' then
                    result := result or v(i);
                end if;
            end loop;
            return result;
        end function or_reduce;
        function and_reduce(v : std_ulogic_vector) return std_ulogic is
        variable result : std_ulogic := '1';
        begin
            for i in v'range loop
                if v(i) = '0' then
                    result := result and v(i);
                end if;
            end loop;
            return result;
        end function and_reduce;

        function even_up(x : integer) return integer is
            begin 
                if (x mod 2) = 0 then
                    return x;
                else
                    return x + 1;
                end if;
            end function even_up;

end package body eig_core_pkg;