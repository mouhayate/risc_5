library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.riscv_types.all;

entity decoder is
Port ( 
    instr_i       : in  STD_LOGIC_VECTOR (31 downto 0);
    isLoad_o      : out STD_LOGIC;
    isStore_o     : out STD_LOGIC;
    isALUreg_o    : out STD_LOGIC;
    isBranch_o    : out STD_LOGIC;
    isSYSTEM_o    : out STD_LOGIC;
    isJAL_o       : out STD_LOGIC;
    isJALR_o      : out STD_LOGIC;
    isJALorJALR_o : out STD_LOGIC;
    isAuipc_o     : out STD_LOGIC;
    isLui_o       : out STD_LOGIC;

    isCSRRS_o     : out STD_LOGIC;
    isEBreak_o    : out STD_LOGIC;

    isByte_o      : out STD_LOGIC;
    isHalf_o      : out STD_LOGIC;

    -- sign extension pour le load 

    funct3_o      : out STD_LOGIC_VECTOR ( 2 downto 0);
    funct7_o      : out STD_LOGIC_VECTOR ( 6 downto 0);

    csrId_o       : out STD_LOGIC_VECTOR ( 1 downto 0);

    rs1_o         : out STD_LOGIC_VECTOR ( 4 downto 0);
    rs2_o         : out STD_LOGIC_VECTOR ( 4 downto 0);
    rdId_o        : out STD_LOGIC_VECTOR ( 4 downto 0)
 );
end decoder;

architecture arch of decoder is

    
begin

    -- optcode
    isLoad_o      <= '1' when instr_i(6 downto 0) = "0000011" else '0';
    isStore_o     <= '1' when instr_i(6 downto 0) = "0100011" else '0';
    isALUreg_o    <= '1' when instr_i(6 downto 0) = "0010011" else '0';
    isBranch_o    <= '1' when instr_i(6 downto 0) = "1100011" else '0';
    isSYSTEM_o    <= instr_is_system( instr_i ); 

    isJAL_o       <= '1' when instr_i(6 downto 0) = "1101111" else '0';
    isJALR_o      <= '1' when instr_i(6 downto 0) = "1100111" else '0';
    isJALorJALR_o <= '1' when instr_i(6 downto 0) = "1100111" OR instr_i(6 downto 0) = "1101111" else '0';

    isAuipc_o     <= '1' when instr_i(6 downto 0) = "0010111" else '0';
    isLui_o       <= '1' when instr_i(6 downto 0) = "0110111" else '0';

    isByte_o      <= '1' when instr_i(14 downto 12)= "000" else '0';
    isHalf_o      <= '1' when instr_i(6 downto 0) = "0000011" else '0';

    funct3_o      <= instr_i(14 downto 12);
    funct7_o      <= instr_i(31 downto 25);

    rs1_o         <= instr_rs1_id( instr_i );-- j'utilise la fonction 
    rs2_o         <= instr_rs2_id( instr_i );
    rdId_o        <= instr_rd_id( instr_i );


    csrId_o       <= instr_csr_id( instr_i );
    isCSRRS_o     <= instr_is_csrrs ( instr_i );
    isEBreak_o    <= instr_is_ebreak( instr_i );

end arch;
 
