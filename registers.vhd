library IEEE;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity registers is
Port ( 
   CLOCK    : in   STD_LOGIC;
   RESET    : in   STD_LOGIC;
   RS1_id   : IN   STD_LOGIC_VECTOR( 4 DOWNTO 0);
   RS2_id   : IN   STD_LOGIC_VECTOR( 4 DOWNTO 0);

   RD_id    : IN   STD_LOGIC_VECTOR( 4 DOWNTO 0);
   RD_id_we : IN   STD_LOGIC;
   DATA_rd  : IN   STD_LOGIC_VECTOR(31 DOWNTO 0);

   DATA_rs1 : OUT  STD_LOGIC_VECTOR(31 DOWNTO 0);
   DATA_rs2 : OUT  STD_LOGIC_VECTOR(31 DOWNTO 0)
 );
end registers;


architecture arch of registers is

   ---------------------------------------------------------------------------------------------------
   type RegFile is array (0 to 31) of STD_LOGIC_VECTOR(31 downto 0);

   impure function InitRegisters(RamFileName : in string)
      return RegFile is
         variable RAM : RegFile;
   begin
      for I in RegFile'range loop
         RAM(I) := x"00000000";
      end loop;
      return RAM;
   end function;
   
   SIGNAL registerFile : RegFile := InitRegisters("FAKE_STRING.hex");

begin

   register_filew : process(CLOCK)
   begin
      if CLOCK'event and CLOCK='1' then  
         if (RD_id_we = '1') then 
            registerFile(to_integer(unsigned(RD_id))) <= DATA_rd;
         end if;
      end if;
   end process;
   
   register_filer : process(CLOCK)
   begin
      if CLOCK'event and CLOCK='1' then  
         DATA_rs1 <= registerFile(to_integer(unsigned(RS1_id)));
         DATA_rs2 <= registerFile(to_integer(unsigned(RS2_id)));
      end if;
   end process;
   
end arch;
 

