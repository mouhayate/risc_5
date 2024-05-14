library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
 
entity alu is
Port ( 
   rs1_v             : in  STD_LOGIC_VECTOR (31 downto 0);
   rs2_v             : in  STD_LOGIC_VECTOR (31 downto 0);
   isALUreg          : in  STD_LOGIC;
   isBranch          : in  STD_LOGIC;
   isAluSubstraction : in  STD_LOGIC;
   func3             : in  STD_LOGIC_VECTOR ( 2 downto 0);
   imm_v             : in  STD_LOGIC_VECTOR (31 downto 0);

   aluOut_v          : out STD_LOGIC_VECTOR (31 downto 0);
   aluPlus_v         : out STD_LOGIC_VECTOR (31 downto 0);-- ne sert a rien
   takeBranch        : out STD_LOGIC
 );
end alu;
 

architecture arch of alu is
  SIGNAL beq , bne , btl , bge, bltu , bgeu : STD_LOGIC;  
  SIGNAL v_plus , v_minus , v_xor , v_or, v_and , v_sll , v_srl, v_sra , opt2 , v_slt , v_sltu : STD_LOGIC_VECTOR(31 downto 0);  
begin
  
    
    opt2 <= rs2_v when isALUreg = '1' else imm_v; 
    
      if(isBranch = '1') then --beq
        if(func3 = "000") then 
          if(signed(rs1_v) = signed(rs2_v)) then
            takeBranch <= '1';
          else 
            takeBranch <= '0';
          end if;

        end if;

        if(func3 = "001") then --bne
          if(signed(rs1_v) /= signed(rs2_v)) then
            takeBranch <= '1';
          else 
            takeBranch <= '0';
          end if;
        end if;

        if(func3 = "100") then -- blt
          if(signed(rs1_v) < signed(rs2_v)) then
            takeBranch <= '1';
          else 
            takeBranch <= '0';
          end if;
        end if;

        if(func3 = "101") then -- bge
          if(signed(rs1_v) >= signed(rs2_v)) then
            takeBranch <= '1';
          else 
            takeBranch <= '0';
          end if;
        end if;

        if(func3 = "110") then --bltu
          if(unsigned(rs1_v) < unsigned(rs2_v)) then
            takeBranch <= '1';
          else 
            takeBranch <= '0';
          end if;
        end if;

        if(func3 = "111") then -- bgeu
          if(unsigned(rs1_v) >= unsigned(rs2_v)) then
            takeBranch <= '1';
          else 
            takeBranch <= '0';
          end if;
        end if;
      else
      takeBranch <= '0';
      end if;


    -- R & I operation
    v_plus    <= STD_logic_vector(signed(rs1_v) + signed(opt2)) ;
    v_minus   <= STD_logic_vector(signed(rs1_v) - signed(rs2_v));
    v_xor     <= rs1_v xor opt2;
    v_or      <= rs1_v or  opt2;
    v_and     <= rs1_v and opt2;
    v_sll     <= STD_LOGIC_VECTOR(shift_left(unsigned(rs1_v) , to_integer(unsigned(opt2(4 downto 0)))));
    v_srl     <= STD_LOGIC_VECTOR(shift_right(unsigned(rs1_v) , to_integer(unsigned(opt2(4 downto 0)))));
    v_sra     <= STD_LOGIC_VECTOR(shift_right(signed(rs1_v) , to_integer(unsigned(opt2(4 downto 0))))); -- msb extends
    v_slt     <= STD_LOGIC_VECTOR(to_unsigned(1,32)) when (signed(rs1_v) < signed(opt2)) else (others => '0');
    v_sltu    <= STD_LOGIC_VECTOR(to_unsigned(1,32)) when (unsigned(rs1_v) < unsigned(opt2)) else (others => '0');

  
  

    aluOut_v <= v_plus  when func3 = "000" and (isAluSubstraction = '0' or (isAluSubstraction = '1' and isALUreg = '0')) else -- soustraction avec un nombre negative
                v_minus when func3 = "000" and isAluSubstraction = '1' else
                v_xor   when func3 = "100" else --0x4
                v_or    when func3 = "110" else --0x6
                v_and   when func3 = "111" else --0x7
                v_sll   when func3 = "001" else --0x1
                v_srl   when func3 = "101" and isAluSubstraction = '0' else --0x5
                v_sra   when func3 = "101" and isAluSubstraction = '1' else --msb extends
                v_slt   when func3 = "010" else -- 0x2
                v_sltu  when func3 = "011" ; -- 0x3

end arch;
 
