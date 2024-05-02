library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use work.riscv_types.all;

entity riscv is
    GENERIC(
        file_prog : STRING  := "../../soft/PROGROM.hex32";
        file_data : STRING  := "../../soft/DATARAM.hex32"
    ); 
Port ( 
   CLK           : in  STD_LOGIC;
   resetn        : in  STD_LOGIC;
   IO_mem_addr   : out STD_LOGIC_VECTOR (31 downto 0);
   IO_mem_rdata  : in  STD_LOGIC_VECTOR (31 downto 0);
   IO_mem_wdata  : out STD_LOGIC_VECTOR (31 downto 0);
   IO_mem_rd     : out STD_LOGIC;
   IO_mem_wr     : out STD_LOGIC
 ); 
end riscv; 


architecture arch of riscv is

   ---------------------------------------------------------------------------------------------------
   --
   -- State machine declaration
   --

   constant F_bit : INTEGER := 0;
   constant D_bit : INTEGER := 1;
   constant E_bit : INTEGER := 2;
   constant M_bit : INTEGER := 3;
   constant W_bit : INTEGER := 4;

   constant F_state : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00001"; 
   constant D_state : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00010";
   constant E_state : STD_LOGIC_VECTOR(4 DOWNTO 0) := "00100";
   constant M_state : STD_LOGIC_VECTOR(4 DOWNTO 0) := "01000";
   constant W_state : STD_LOGIC_VECTOR(4 DOWNTO 0) := "10000";


   SIGNAL state : STD_LOGIC_VECTOR (4 downto 0);
   SIGNAL  halt : STD_LOGIC;

   ---------------------------------------------------------------------------------------------------
   --
   -- Internal counters for performance estimation
   --



   ---------------------------------------------------------------------------------------------------
   --
   -- Definition and initialization of the program ROM
   --

    COMPONENT mem_rom is
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
    end COMPONENT;
    
   ---------------------------------------------------------------------------------------------------
   --
   -- Definition and initialization of the local data RAM
   --

    COMPONENT mem_ram is
        GENERIC(
            RAM_ADDR_BITS : INTEGER := 14;
            filename      : STRING  := "../../soft/DATARAM.hex32"
        );
        Port ( 
            CLOCK   : IN  STD_LOGIC;
            ADDR_RW : IN  STD_LOGIC_VECTOR(RAM_ADDR_BITS-1 DOWNTO 0);
            ENABLE  : IN  STD_LOGIC;
            WRITE_M : IN  STD_LOGIC_VECTOR( 3 DOWNTO 0);
            DATA_W  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            DATA_R  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
         );
    END COMPONENT;

    COMPONENT decoder is
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
    END COMPONENT;
    
    COMPONENT immediate is
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
    end COMPONENT;
    
    COMPONENT registers is
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
    end COMPONENT;

    COMPONENT registers_luts is
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
    end COMPONENT;


    COMPONENT fetch is
    Port ( 
       CLK                 : in  STD_LOGIC;
       resetn              : in  STD_LOGIC;
       enable_f            : in  STD_LOGIC;
       enable_m            : in  STD_LOGIC;
       jumpOrBranchAddress : in  STD_LOGIC_VECTOR (31 downto 0);
       jumpOrBranch        : in  STD_LOGIC;
       pc_value            : out STD_LOGIC_VECTOR (31 downto 0)
     );
    end COMPONENT;

    COMPONENT alu is
    Port ( 
       rs1_v             : in STD_LOGIC_VECTOR (31 downto 0);
       rs2_v             : in STD_LOGIC_VECTOR (31 downto 0);
       isALUreg          : in STD_LOGIC;
       isBranch          : in STD_LOGIC;
       isAluSubstraction : in STD_LOGIC;
       func3             : in STD_LOGIC_VECTOR ( 2 downto 0);
       imm_v             : in STD_LOGIC_VECTOR (31 downto 0);

       aluOut_v          : out STD_LOGIC_VECTOR (31 downto 0);
       aluPlus_v         : out STD_LOGIC_VECTOR (31 downto 0);
       takeBranch        : out STD_LOGIC
    );
    end COMPONENT;

    COMPONENT mem_load 
        Port ( 
            ADDR_R      : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            DATA_R      : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            is_byte     : IN  STD_LOGIC;
            is_half     : IN  STD_LOGIC;
            is_sign_ext : IN  STD_LOGIC;
            data_value  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
         );
    end COMPONENT;

    COMPONENT mem_store 
        Port ( 
            ADDR_W     : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0);
            DATA_W     : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
            is_byte    : IN  STD_LOGIC;
            is_half    : IN  STD_LOGIC;
            data_mask  : OUT STD_LOGIC_VECTOR( 3 DOWNTO 0);
            data_value : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
         );
    end COMPONENT;

   ---------------------------------------------------------------------------------------------------
   --
   -- Load-Store
   --

   SIGNAL F_PC    : STD_LOGIC_VECTOR (31 downto 0);

   --localparam NOP = 32'b0000000_00000_00000_000_00000_0110011; 
   constant NOP : STD_LOGIC_VECTOR (31 downto 0) := "00000000000000000000000000110011";
   
   --  These two signals come from the Execute stage **/
   SIGNAL jumpOrBranchAddress : STD_LOGIC_VECTOR (31 downto 0); 
   SIGNAL jumpOrBranch        : STD_LOGIC;

   SIGNAL wbEnable            : STD_LOGIC;

   SIGNAL FD_PC               : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL FD_instr            : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL DE_instr            : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL EM_instr            : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL MW_instr            : STD_LOGIC_VECTOR (31 downto 0);

   ---------------------------------------------------------------------------------------------------
   --
   -- Decode stage
   --

   SIGNAL D_isLoad            : STD_LOGIC;
   SIGNAL D_isJALorJALR       : STD_LOGIC;
   SIGNAL D_isJAL             : STD_LOGIC;
   SIGNAL D_isJALR            : STD_LOGIC;
   SIGNAL D_isALUreg          : STD_LOGIC;
   SIGNAL D_isBranch          : STD_LOGIC;
   SIGNAL D_isStore           : STD_LOGIC;
   SIGNAL D_isSYSTEM          : STD_LOGIC;
   SIGNAL D_isAuipc           : STD_LOGIC;
   SIGNAL D_isLui             : STD_LOGIC;
   SIGNAL D_isCSRRS           : STD_LOGIC;
   SIGNAL D_isEBREAK          : STD_LOGIC;

   SIGNAL D_imm               : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL D_Iimm              : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL D_Simm              : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL D_Uimm              : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL D_Jimm              : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL D_Bimm              : STD_LOGIC_VECTOR (31 downto 0);

   ---------------------------------------------------------------------------------------------------
   --
   -- Load-Store
   --

   SIGNAL D_isByte    : STD_LOGIC;
   SIGNAL D_isHalf    : STD_LOGIC;

   SIGNAL D_funct3    : STD_LOGIC_VECTOR ( 2 downto 0);
   SIGNAL D_funct7    : STD_LOGIC_VECTOR ( 6 downto 0);
   SIGNAL D_rs1Id     : STD_LOGIC_VECTOR ( 4 downto 0);
   SIGNAL D_rs2id     : STD_LOGIC_VECTOR ( 4 downto 0);
   SIGNAL D_rdId      : STD_LOGIC_VECTOR ( 4 downto 0);
   SIGNAL D_csrId     : STD_LOGIC_VECTOR ( 1 downto 0);

   SIGNAL DE_isByte    : STD_LOGIC;
   SIGNAL DE_isHalf    : STD_LOGIC;
   SIGNAL E_addr       : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL E_storeMask1 : STD_LOGIC_VECTOR ( 3 downto 0);
   SIGNAL E_storeMask  : STD_LOGIC_VECTOR ( 3 downto 0);


   ---------------------------------------------------------------------------------------------------
   --
   -- Decode internals
   --

   SIGNAL DE_rs1_v     : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL DE_rs2_v     : STD_LOGIC_VECTOR (31 downto 0);

   SIGNAL DE_isALUreg  : STD_LOGIC;
   SIGNAL DE_isBranch  : STD_LOGIC;
   SIGNAL DE_isJALR    : STD_LOGIC;
   SIGNAL DE_isJAL     : STD_LOGIC;
   SIGNAL DE_isLoad    : STD_LOGIC;
   SIGNAL DE_isStore   : STD_LOGIC;
   SIGNAL DE_isEBREAK  : STD_LOGIC;
   SIGNAL DE_isCSRRS   : STD_LOGIC;

   SIGNAL DE_isAuipc   : STD_LOGIC;
   SIGNAL DE_isLui     : STD_LOGIC;

   SIGNAL DE_imm       : STD_LOGIC_VECTOR (31 downto 0);

   SIGNAL DE_rdId      : STD_LOGIC_VECTOR ( 4 downto 0);
   SIGNAL DE_csrId     : STD_LOGIC_VECTOR ( 1 downto 0);
   SIGNAL DE_funct3    : STD_LOGIC_VECTOR ( 2 downto 0);
   SIGNAL DE_funct7    : STD_LOGIC_VECTOR ( 6 downto 0);

   SIGNAL DE_isJALorJALR             : STD_LOGIC;
   
   SIGNAL DE_PC            : STD_LOGIC_VECTOR (31 downto 0);


   ---------------------------------------------------------------------------------------------------

   SIGNAL E_STORE_data : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL E_isIO       : STD_LOGIC;
   SIGNAL E_isRAM      : STD_LOGIC;
                              
   SIGNAL E_word_addr  : STD_LOGIC_VECTOR (13 downto 0);

    -- ALU signals

   SIGNAL E_aluPlus    : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL E_aluOut     : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL E_takeBranch : STD_LOGIC;

   ---------------------------------------------------------------------------------------------------

   SIGNAL EM_Eresult  : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL E_result    : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL EM_addr     : STD_LOGIC_VECTOR ( 1 downto 0);
   SIGNAL EM_isIO     : STD_LOGIC;
   SIGNAL EM_isLoad   : STD_LOGIC;
   SIGNAL EM_isStore  : STD_LOGIC;
   SIGNAL EM_isBranch : STD_LOGIC;
   SIGNAL EM_isCSRRS  : STD_LOGIC;
   SIGNAL EM_rdId     : STD_LOGIC_VECTOR ( 4 downto 0);
   SIGNAL EM_funct3   : STD_LOGIC_VECTOR ( 2 downto 0);

   SIGNAL EM_isByte    : STD_LOGIC;
   SIGNAL EM_isHalf    : STD_LOGIC;

   SIGNAL EM_CSRdata  : STD_LOGIC_VECTOR (31 downto 0);

   SIGNAL EM_Mdata    : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL EM_IOdata   : STD_LOGIC_VECTOR (31 downto 0);
   
   SIGNAL EM_JumpOrBranch        : STD_LOGIC;
   SIGNAL EM_JumpOrBranchAddress : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL E_JumpOrBranchAddress  : STD_LOGIC_VECTOR (31 downto 0);

   ---------------------------------------------------------------------------------------------------

   SIGNAL M_sext      : STD_LOGIC;

   SIGNAL M_LOAD_H    : STD_LOGIC_VECTOR (15 downto 0);
   SIGNAL M_LOAD_B    : STD_LOGIC_VECTOR ( 7 downto 0);
   SIGNAL M_LOAD_sign : STD_LOGIC;

   SIGNAL M_WLoadData : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL M_WBdata    : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL M_wbEnable  : STD_LOGIC;

   SIGNAL M_Mresult   : STD_LOGIC_VECTOR (31 downto 0);

   SIGNAL MW_WBdata   : STD_LOGIC_VECTOR (31 downto 0);
   SIGNAL MW_rdId     : STD_LOGIC_VECTOR ( 4 downto 0);
   SIGNAL MW_wbEnable : STD_LOGIC;
   
   --
   ---------------------------------------------------------------------------------------------------
   --

    COMPONENT csr_registers is
    Port ( 
        CLK      :  in STD_LOGIC;
        resetn   :  in STD_LOGIC;
        instr_en :  in STD_LOGIC;
        csr_id   :  in STD_LOGIC_VECTOR ( 1 downto 0);
        word_v   : out STD_LOGIC_VECTOR (31 downto 0)
    );
    end COMPONENT;
    
   --
   ---------------------------------------------------------------------------------------------------
   --

begin

   --
   ---------------------------------------------------------------------------------------------------
   --

   process(clk)
   begin
     
     if rising_edge(clk) then
         if resetn = '0' then
            state  <= F_state;
         elsif halt = '0' then
            state <= state(3 downto 0) & state(4);
         end if;
     end if;
   end process;

   --
   ---------------------------------------------------------------------------------------------------
   --

    prog_rom : mem_rom
    GENERIC MAP(
        RAM_ADDR_BITS => 14,
        filename      => file_prog
    )
    PORT MAP ( 
        CLOCK  => clk,
        ENABLE => state(F_bit),         -- an enable bit 
        ADDR_R => F_PC(15 downto 2),
        DATA_O => FD_instr
    );

   --
   ---------------------------------------------------------------------------------------------------
   --

    pc_fetch : fetch
    PORT MAP ( 
       CLK                 => clk,
       resetn              => resetn,
       enable_f            => state(F_bit),
       enable_m            => state(M_bit),
       jumpOrBranchAddress => jumpOrBranchAddress,
       jumpOrBranch        => jumpOrBranch,
       pc_value            => F_PC
     );

    --
    -- On conserve la valeur du PC pour l'étage de decode
    --

    process(clk)
    begin   
        if rising_edge(clk) then
            if resetn = '0' then
                FD_PC     <= (others => '0');
            elsif state(F_bit) = '1' then
                FD_PC    <= F_PC;
            end if;
        end if;
    end process;

   --/******************************************************************************/
   --
   -- D: Instruction decode ***/
   --
   -- These three signals come from the Writeback stage **/
   --


    dec: decoder
    PORT MAP( 
        instr_i       => FD_instr,
        isLoad_o      => D_isLoad,
        isStore_o     => D_isStore,    
        isALUreg_o    => D_isALUreg,
        isBranch_o    => D_isBranch,
        isSYSTEM_o    => D_isSYSTEM,   
        isJAL_o       => D_isJAL,  
        isJALR_o      => D_isJALR,
        isJALorJALR_o => D_isJALorJALR,
        isAuipc_o     => D_isAuipc,
        isLui_o       => D_isLui,  
        isCSRRS_o     => D_isCSRRS,
        isEBreak_o    => D_isEBREAK,

        isByte_o      => D_isByte,
        isHalf_o      => D_isHalf,
    
        -- sign extension pour le load 
    
        funct3_o      => D_funct3,  
        funct7_o      => D_funct7,
    
        csrId_o       => D_csrId,
    
        rs1_o         => D_rs1Id,
        rs2_o         => D_rs2id,
        rdId_o        => D_rdId
    );

   -----------

    imm : immediate
    PORT MAP(
       INSTR    => FD_instr, 
       isStore  => D_isStore, 
       isLoad   => D_isLoad,  
       isbranch => D_isbranch,
       isJAL    => D_isJAL,
       isAuipc  => D_isAuipc, 
       isLui    => D_isLui,   
       imm      => D_imm
    );


   -----------

    process(clk)
    begin   
        if rising_edge(clk) then
            if resetn = '0' then
                DE_instr                   <= (others => '0');
                DE_isALUreg                <= '0'; -- OK
                DE_isBranch                <= '0'; -- OK
                DE_isLoad                  <= '0'; 
                DE_isStore                 <= '0';
                DE_isJALR                  <= '0';
                DE_isJAL                   <= '0';
                DE_isAuipc                 <= '0';
                DE_isLui                   <= '0';
                DE_isCSRRS                 <= '0';
                DE_isEBREAK                <= '0';
                DE_imm                     <= (others => '0');
                DE_rdId                    <= (others => '0');
                DE_funct3                  <= (others => '0');
                DE_funct7                  <= (others => '0');
                DE_csrId                   <= (others => '0');
                DE_isJALorJALR             <= '0';
                DE_isByte                  <= '0';
                DE_isHalf                  <= '0';
                DE_PC                      <= (others => '0');
            elsif state(D_bit) = '1' then
                DE_instr            <= FD_INSTR;
                DE_isALUreg         <= D_isALUreg; -- OK
                DE_isBranch         <= D_isBranch; -- OK
                DE_isLoad           <= D_isLoad; 
                DE_isStore          <= D_isStore;
                DE_isJALR           <= D_isJALR;
                DE_isJAL            <= D_isJAL;
                DE_isAuipc          <= D_isAuipc;
                DE_isLui            <= D_isLui;  
                DE_isCSRRS          <= D_isCSRRS;
                DE_isEBREAK         <= D_isEBREAK;
                DE_imm              <= D_imm; 
                DE_rdId             <= D_rdId;
                DE_funct3           <= D_funct3;
                DE_funct7           <= D_funct7;
                DE_csrId            <= D_csrId;
                DE_isByte           <= D_isByte;
                DE_isHalf           <= D_isHalf;
                DE_PC               <= FD_PC; -- on transmet le PC
                DE_isJALorJALR      <= D_isJALorJALR;
            end if;
        end if;
    end process;


   --
   ---------------------------------------------------------------------------------------------------
   --

   --
   -- On valide l'écriture dans les registres lorsque l'on est dans le dernier état
   --
    
    wbEnable <= MW_wbEnable and state(W_bit);

    regs : registers
    PORT MAP(
       CLOCK    => clk,
       reset    => '0',         -- to change

       RD_id    => MW_rdId,     -- signaux du write back
       RD_id_we => wbEnable,    -- signaux du write back
       DATA_rd  => MW_WBdata,   -- signaux du write back

       RS1_id   => D_rs1Id,     -- signaux du decode
       RS2_id   => D_rs2Id,     -- signaux du decode
       DATA_rs1 => DE_rs1_v,    -- signaux vers l'execute
       DATA_rs2 => DE_rs2_v     -- signaux vers l'execute
    );


   -------------------------------------------------------------------------------------------------
   --
   --  E: Execute
   --

    i_alu : alu
    PORT MAP(
       rs1_v             => DE_rs1_v,
       rs2_v             => DE_rs2_v,
       isALUreg          => DE_isALUreg,  -- todo
       isBranch          => DE_isBranch,  -- todo
       isAluSubstraction => DE_funct7(5), --funct7_is_SUB( DE_funct7 ),
       func3             => DE_funct3,
       imm_v             => DE_imm,
       aluOut_v          => E_aluOut,
       aluPlus_v         => E_aluPlus,
       takeBranch        => E_takeBranch
     );
   

    --
    --
    -- 

   E_addr <=  STD_LOGIC_VECTOR( SIGNED(DE_rs1_v) + SIGNED(DE_imm) );

    mem_str : mem_store 
    Port map( 
            ADDR_W     => E_addr(1 downto 0),
            DATA_W     => DE_rs2_v,
            is_byte    => DE_isByte,
            is_half    => DE_isHalf,
            data_mask  => E_storeMask1,
            data_value => E_STORE_data
        );


   -- bidouille interne
                    
   E_isRAM            <= NOT E_addr(22); -- 0x4000....
   E_storeMask        <= E_storeMask1  WHEN E_isRAM = '1' and DE_isStore = '1' ELSE "0000";

   E_isIO             <= E_addr(22);         -- BLG, why IO ?
   E_isRAM            <= not E_isIO;         -- pq le mapping est dans la proc ?
   E_word_addr        <= E_addr(15 downto 2);

   --/****************** Store ******************************/

   IO_mem_addr        <= E_addr;
   IO_mem_wr          <= state(E_bit) and DE_isStore and E_isIO; 
   IO_mem_rd          <= state(E_bit) and DE_isLoad  and E_isIO;
   IO_mem_wdata       <= DE_rs2_v;

   --
   ---------------------------------------------------------------------------------------------------
   --
   -- Performance registers from CSR
   --

    csr_reg : csr_registers
    PORT MAP ( 
       CLK      => clk,
       resetn   => resetn,
       instr_en => state(M_bit), -- indique lorsqu'une instruction a ete consommme par le u-proc
       csr_id   => DE_csrId,     -- from decode 
       word_v   => EM_CSRdata    -- to execute
     );

   --
   ---------------------------------------------------------------------------------------------------
   --

    --
    -- Branch unit
    --
    E_JumpOrBranchAddress <= STD_LOGIC_VECTOR( SIGNED(DE_rs1_v) + SIGNED(DE_imm) ) when DE_isJALR = '1' else
                             STD_LOGIC_VECTOR( SIGNED(DE_PC)    + SIGNED(DE_imm) ) when DE_isJAL  = '1' else
                             STD_LOGIC_VECTOR( SIGNED(DE_PC)    + SIGNED(DE_imm) ); -- when cond. branch


    --
    -- Result selection unit
    --
    E_result              <= STD_LOGIC_VECTOR( SIGNED(DE_PC) + TO_SIGNED(4, 32) ) when DE_isJALR  = '1' else
                             STD_LOGIC_VECTOR( SIGNED(DE_PC) + TO_SIGNED(4, 32) ) when DE_isJAL   = '1' else
                             DE_imm                                               when DE_isLui   = '1' else
                             STD_LOGIC_VECTOR( SIGNED(DE_PC)    + SIGNED(DE_imm)) when DE_isAuipc = '1' else
                             E_aluOut;

   process(clk)
   begin   
      if rising_edge(clk) then
         if state(E_bit) = '1' then

            EM_instr               <= DE_INSTR;
            EM_Eresult             <= E_result;
            EM_JumpOrBranch        <= DE_isJALorJALR or (DE_isBranch and E_takeBranch);
            EM_JumpOrBranchAddress <= E_JumpOrBranchAddress;

            EM_addr                <= E_addr(1 downto 0);
            EM_isIO                <= E_addr(22);
            
            EM_isLoad   <= DE_isLoad;
            EM_isStore  <= DE_isStore;
            EM_isByte   <= DE_isByte;
            EM_isHalf   <= DE_isHalf;
            
            EM_isBranch <= DE_isBranch;
            EM_isCSRRS  <= DE_isCSRRS;
            EM_rdId     <= DE_rdId;
            EM_funct3   <= DE_funct3;
            
         end if;
      end if;
   end process;
      
   halt <= resetn and DE_isEBREAK;

   --
   ---------------------------------------------------------------------------------------------------
   --

    data_ram : mem_ram
    GENERIC MAP(
        RAM_ADDR_BITS => 14,
        filename      => file_data
    )
    PORT MAP( 
        CLOCK   => clk,
        ADDR_RW => E_word_addr,     -- adresse en lecture / ecriture
        ENABLE  => state(E_bit),    -- on realise d'action en fin de cycle execute
        WRITE_M => E_storeMask, 
        DATA_W  => E_STORE_data,
        DATA_R  => EM_Mdata
     );
   
   --
   ---------------------------------------------------------------------------------------------------
   --
   -- M: Memory stage
   --

   M_sext    <= NOT EM_funct3(2); -- funct3_is_sign_ext( EM_funct3 ); -- NOT EM_funct3(2);

   --
   ---------------------------------------------------------------------------------------------------
   --
   -- L: Load stage 
   --


    mem_ld : mem_load 
    PORT MAP ( 
        ADDR_R      => EM_addr,
        DATA_R      => EM_Mdata,
        is_byte     => EM_isByte,
        is_half     => EM_isHalf,
        is_sign_ext => M_sext,
        data_value  => M_Mresult
     );

   --
   --------------------------------------------------------------------------------------
   --
   --
   --

    process(clk)
    begin   
        if rising_edge(clk) then
	        EM_IOdata  <= IO_mem_rdata;
        end if;
    end process;


   --------------------------------------------------------------------------------------
   --
   -- Execute to Memory 
   --

   -- 
   -- Should the Rd register be updated ?
   --
   M_wbEnable  <= NOT (EM_isBranch OR EM_isStore OR to_stdl(EM_rdId = "00000"));

   -- 
   -- select the correct value for Rd register writing
   -- 
   M_WLoadData <= EM_IOdata  WHEN EM_isIO = '1' ELSE M_Mresult; -- IO ou bien RAM data
   
   M_WBdata    <= M_WLoadData WHEN EM_isLoad  = '1' ELSE -- DATA from memory or IOs
                  EM_CSRdata  WHEN EM_isCSRRS = '1' ELSE -- registre CSR
                  EM_Eresult;                            -- ALU output
   
    process(clk)
    begin   
        if rising_edge(clk) then
            if state(M_bit) = '1' then
                MW_instr    <= EM_INSTR;    -- processor instruction
                MW_rdId     <= EM_rdId;     -- destination register 
                MW_WBdata   <= M_WBdata;    -- data to write
                MW_wbEnable <= M_wbEnable;  -- write enable signal
            end if;
        end if;
    end process;

   --
   ---------------------------------------------------------------------------------------------------
   --
   
   jumpOrBranchAddress <= EM_JumpOrBranchAddress;
   jumpOrBranch        <= EM_JumpOrBranch;

   --
   ---------------------------------------------------------------------------------------------------
   --

   --
   -- On gere la fin de la simulation lorsque le "main" retourne vers le systeme
   --

   process(clk)
   begin
     if rising_edge(clk) then
         if resetn = '1' and DE_isEBREAK = '1' then
            assert false report "The program finished its execution normally !" severity failure;
         end if;
     end if;
   end process;
      
   --
   ---------------------------------------------------------------------------------------------------
   --
   
end arch;
 
