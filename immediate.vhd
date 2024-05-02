library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

use work.riscv_types.all;

entity immediate is
Port ( 
   INSTR    : in  STD_LOGIC_VECTOR (31 downto 0);
   isStore  : in  STD_LOGIC;
   isLoad   : in  STD_LOGIC;
   isbranch : in  STD_LOGIC;
   isJAL    : in  STD_LOGIC;
   isAuipc  : in  STD_LOGIC;
   isLui    : in  STD_LOGIC;
   imm      : out STD_LOGIC_VECTOR (31 downto 0)
 );
end immediate; 


architecture arch of immediate is
    SIGNAL S_imm : STD_LOGIC_VECTOR (31 downto 0); -- instruction de type s Store 
    SIGNAL I_imm : STD_LOGIC_VECTOR (31 downto 0); -- instruction de type I (Load)
    SIGNAL J_imm : STD_LOGIC_VECTOR (31 downto 0); -- instruction de type J jump and link 
    SIGNAL U_imm : STD_LOGIC_VECTOR (31 downto 0); -- instruction de type U 
    SIGNAL B_imm : STD_LOGIC_VECTOR (31 downto 0); -- instruction de type B 
    
begin
    -- type J  imm[20|10:1|11|19:12] 
    J_imm(31 downto 21)    <= repeat_bit(J_imm(20) , 11);
    J_imm(20)              <= INSTR(31);
    J_imm(19 downto 12)    <= INSTR(19 downto 12);
    J_imm(11)              <= INSTR(20);
    J_imm(10 downto 1)     <= INSTR(30 downto 21);
    J_imm(0)               <= '0';

    -- type I imm[11|0]
    I_imm(31 downto 12)    <= repeat_bit(I_imm(11) , 20);

    -- type U imm[31|12]
    U_imm(31 downto 12)    <= INSTR(31 downto 12);
    U_imm(11 downto 0)    <= (others => '0');
    
    -- type S imm[11|5] & imm[4|0]
    S_imm(31 downto 12)    <= repeat_bit(S_imm(11) , 20); -- definie dans risc5type
    S_imm(11 downto 5)     <= INSTR(31 downto 25);
    S_imm(4 downto 0)      <= INSTR(11 downto 7);
    

    -- type S imm[12|10:5] & imm[4|1:11]
    B_imm(0)               <= '0';
    B_imm(4 downto 1)      <= INSTR(11 downto 8);
    B_imm(10 downto 5)     <= INSTR(30 downto 25);
    B_imm(11)              <= INSTR(7);
    B_imm(12)              <= INSTR(31);
    B_imm(31 downto 13)    <= repeat_bit(B_imm(12) , 19);
    
     
    -- instruction 
    imm     <= U_imm when isLui   = '1' or isAuipc = '1' else
                    S_imm when isStore = '1' else
                        I_imm when isLoad = '1' else
                            J_imm when isJAL = '1' else
                                B_imm when isbranch = '1';
 
end arch;
