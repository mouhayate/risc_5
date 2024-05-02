library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.riscv_types.all;

entity mem_load is 
    Port ( 
        ADDR_R      : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
        DATA_R      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
        is_byte     : IN  STD_LOGIC;
        is_half     : IN  STD_LOGIC;
        is_sign_ext : IN  STD_LOGIC;
        data_value  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
     );
end mem_load;


architecture arch of mem_load is

    SIGNAL Byte , half : STD_LOGIC_VECTOR(31 downto 0);    
    
begin
  multiplex : process(is_sign_ext , DATA_R)
  begin
    if (is_sign_ext = '0') then 
      Byte(31 downto 8) <= (others => '0');
    else 
      byte(31 downto 8)  <= repeat_bit(byte(7) , 24); -- propagation du byte de signe
    end if;
  end process;
   
  multiplex1 : process(is_sign_ext , DATA_R)
  begin
    if (is_sign_ext = '0') then 
      half(31 downto 16) <= (others => '0');
    else  
      half(31 downto 16) <= repeat_bit(half(15), 16); -- propagation du byte de signe
    end if;
  end process;

--  half(31 downto 16) <= repeat_bit(half(15) and is_sign_ext, 16); -- propagation du byte de signe


    Byte(7 downto 0)   <= DATA_R(7 downto 0) when ADDR_R = "00" else
                          DATA_R(15 downto 8) when ADDR_R = "01" else
                          DATA_R(23 downto 16) when ADDR_R = "10" else
                          DATA_R(31 downto 24) when ADDR_R = "11" ;
    
    
    half(15 downto 0)   <= DATA_R(15 downto 0) when ADDR_R(1) = '0' else
                          DATA_R(31 downto 16) when ADDR_R(1) = '1' ;
                        

   
    data_value  <=  Byte when is_byte = '1' else
                    half when is_half = '1' else
                    DATA_R when is_byte = '0' and is_half = '0';
            
end arch;
