library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity fetch is
Port ( 
   CLK                 : in  STD_LOGIC;
   resetn              : in  STD_LOGIC;
   enable_f            : in  STD_LOGIC; --isFetch_s
   enable_m            : in  STD_LOGIC; -- isMemWrite
   jumpOrBranchAddress : in  STD_LOGIC_VECTOR (31 downto 0); -- JumpAdress
   jumpOrBranch        : in  STD_LOGIC; -- is JumpOrBranch
   pc_value            : out STD_LOGIC_VECTOR (31 downto 0) -- PC_v
 );
end fetch;

architecture arch of fetch is

  SIGNAL pc_value_temp : STD_LOGIC_VECTOR (31 downto 0);
    
begin

  instr_fetch : process(CLK) 
  begin
    
    if (resetn = '0') then -- reset asynch
    
      pc_value_temp <= (others => '0');

    elsif CLK'event and CLK='1' then-- clock

      -- si stage = fetch on incremente de 4
      if (enable_f = '1') then
        pc_value_temp <= STD_logic_vector( UNSIGNED(pc_value_temp) + 4); -- on incrementpv de 4
        --STD_logic_vector(signed(rs1_v) + signed(opt2))

      -- si stage = memory et que l'on doit sauter, on charge l'adresse
      elsif(enable_m = '1') then 
        if (jumpOrBranch = '1') then
          pc_value_temp <= jumpOrBranchAddress;
        end if;
      end if; 
    end if; --end clock
  end process;
  
  pc_value <= pc_value_temp; -- affectation immediat

end arch;  
 
