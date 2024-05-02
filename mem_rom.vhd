library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity mem_rom is 
    GENERIC(
        RAM_ADDR_BITS : INTEGER := 14;
        filename      : STRING  := "../../soft/PROGROM.hex32"
    );
    Port ( 
        CLOCK   : IN  STD_LOGIC;
        ENABLE  : IN  STD_LOGIC;
        ADDR_R  : IN  STD_LOGIC_VECTOR(RAM_ADDR_BITS-1 DOWNTO 0);
        DATA_O  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
     );
end mem_rom;


architecture arch of mem_rom is

    TYPE   rom_type IS ARRAY (0 TO ((2**RAM_ADDR_BITS)-1)) OF STD_LOGIC_VECTOR (31 DOWNTO 0);

    impure function InitRomFromFile(RamFileName : in string)
      return rom_type is
        file RomFile         : text open read_mode is RamFileName;
        variable RomFileLine : line;
        variable ROM         : rom_type;
    begin
      for I in rom_type'range loop
         readline(RomFile, RomFileLine);
         hread(RomFileLine, ROM(I));
      end loop;
      return ROM;
    end function;

    SIGNAL memory : rom_type := InitRomFromFile( filename );

begin

  memory_ROM : process(CLOCK)
  begin
    if CLOCK'event and CLOCK='1' then
        if ENABLE = '1' then 
          DATA_O <= memory(to_integer(unsigned(ADDR_R)));
        end if;  
    end if ;
  end process ;
   
end arch;
