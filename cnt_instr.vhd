library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library work;
use work.riscv_types.all;

entity cnt_instr is
Port ( 
   CLK       : in  STD_LOGIC;
   resetn    : in  STD_LOGIC;
   enable    : in  STD_LOGIC;
   counter_v : out STD_LOGIC_VECTOR (63 downto 0)
 );
end cnt_instr; 


architecture arch of cnt_instr is

    SIGNAL count  : UNSIGNED (63 downto 0);

begin

    process(clk)
    begin   
        if rising_edge(clk) then
            if resetn = '0' then
                count  <= to_unsigned(0, 64);
            elsif enable = '1' then
                count  <= count + to_unsigned(1, 64);
            end if;
        end if;
    end process;

    counter_v <= STD_LOGIC_VECTOR( count );

end arch;
