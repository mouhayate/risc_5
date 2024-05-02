library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity mem_store is 
    Port ( 
        ADDR_W     : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
        DATA_W     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        is_byte    : IN  STD_LOGIC;
        is_half    : IN  STD_LOGIC;
        data_mask  : OUT STD_LOGIC_VECTOR( 3 DOWNTO 0);
        data_value : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
     );
end mem_store;


architecture arch of mem_store is
    SIGNAL Byte : STD_LOGIC_VECTOR(31 downto 0); 
    SIGNAL half : STD_LOGIC_VECTOR(31 downto 0); 

begin

  --Byte(31 downto 0)   <= DATA_W(7 downto 0) & DATA_W(7 downto 0) & DATA_W(7 downto 0) & DATA_W(7 downto 0);

  Byte(7 downto 0)    <= DATA_W(7 downto 0); 
  Byte(15 downto 8)   <= DATA_W(7 downto 0);
  Byte(23 downto 16)  <= DATA_W(7 downto 0);
  Byte(31 downto 24)  <= DATA_W(7 downto 0);
 
  half(15 downto 0)  <= DATA_W(15 downto 0);
  half(31 downto 16) <= DATA_W(15 downto 0);
 

    data_value      <= Byte when is_byte = '1' else
                       half when is_half = '1' else 
                       DATA_W;

    data_mask       <=  "0001" when is_byte = '1' and ADDR_W = "00" else
                        "0010" when is_byte = '1' and ADDR_W = "01" else
                        "0100" when is_byte = '1' and ADDR_W = "10"  else
                        "1000" when is_byte = '1' and ADDR_W = "11" else
                        "0011" when is_half = '1' and ADDR_W = "00" else
                        "1100" when is_half = '1' and ADDR_W = "10" else
                        "1111"; -- word
   
end arch;
