library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package eig_core_pkg is
    function saturate(input : signed; target_width : integer) return std_ulogic_vector;

    function or_reduce(v : std_ulogic_vector) return std_ulogic;
    function and_reduce(v : std_ulogic_vector) return std_ulogic;

    function even_up(x : integer) return integer;

    function msb_pos(x : unsigned) return integer;

end package eig_core_pkg;

package body eig_core_pkg is

        function saturate(input : signed; target_width : integer) return std_ulogic_vector is
        variable result : signed(target_width-1 downto 0) := (others => '0');
        begin
            if input'high < target_width-1 then
                result := resize(input, target_width);
            else
                if input(input'high) = '0' then
                    if or_reduce(std_logic_vector(input(input'high downto target_width))) = '1' then
                        result := (others => '1');
                        result(target_width-1) := '0';
                    else
                        result := resize(input, target_width);
                    end if;
                else
                    if and_reduce(std_logic_vector(not input(input'high downto target_width))) = '0' then
                        result := (others => '0');
                        result(target_width-1) := '1';
                    else
                        result := resize(input, target_width);
                    end if;
                end if;
            end if;
            return std_logic_vector(result);
        end function saturate;


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
        
        function msb_pos(x : unsigned) return integer is
        begin   
            for i in x'range loop
                if x(x'length - 1 - i) = '1' then
                    return x'length - 1 - i;
                end if;
            end loop;
            return -1; -- falls alle Bits 0 sind
        end function msb_pos;

end package body eig_core_pkg;