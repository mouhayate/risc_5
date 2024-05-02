library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity mem_ram is
    GENERIC(
        RAM_ADDR_BITS : INTEGER := 14;
        filename      : STRING  := "../../soft/PROGROM.hex32" 
    );
    Port ( 
        CLOCK   : IN  STD_LOGIC;
        ADDR_RW : IN  STD_LOGIC_VECTOR(RAM_ADDR_BITS-1 DOWNTO 0);
        ENABLE  : IN  STD_LOGIC;
        WRITE_M : IN  STD_LOGIC_VECTOR( 3 DOWNTO 0);
        DATA_W  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        DATA_R  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
     );
end mem_ram;


architecture arch of mem_ram is 

    TYPE   ram_type IS ARRAY (0 TO ((2**RAM_ADDR_BITS)-1)) OF STD_LOGIC_VECTOR (31 DOWNTO 0);

    impure function InitRomFromFile(RamFileName : in string)
      return ram_type is
         file RamFile         : text open read_mode is RamFileName;
         variable RamFileLine : line;
         variable RAM         : ram_type;
    begin
      for I in ram_type'range loop
         readline(RamFile, RamFileLine);
         hread(RamFileLine, RAM(I));
      end loop;
      return RAM;
    end function;

    SIGNAL memory : ram_type := InitRomFromFile( filename );
 
begin

    memory_RAM : process(CLOCK)
    begin
      if CLOCK'event and CLOCK='1' then
        if ENABLE = '1' then 
            if (WRITE_M(3) = '1') then
                memory(to_integer(unsigned(ADDR_RW))) (31 downto 24)  <= DATA_W(31 downto 24);
            end if;
                
            if (WRITE_M(2) = '1') then
                memory(to_integer(unsigned(ADDR_RW))) (23 downto 16)  <= DATA_W(23 downto 16);
            end if;

            if (WRITE_M(1) = '1') then
                memory(to_integer(unsigned(ADDR_RW))) (15 downto 8)  <= DATA_W(15 downto 8);
            end if;
                
            if (WRITE_M(0) = '1') then
                memory(to_integer(unsigned(ADDR_RW))) (7 downto 0) <= DATA_W(7 downto 0); -- on remplie par bloc de 8
            end if;
        end if; 
        DATA_R <= memory(to_integer(unsigned(ADDR_RW))); 
      end if ;
    end process ;

end arch;
 
