library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

package riscv_types is

    function instr_is_system ( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return std_logic;
    function instr_is_ebreak ( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return std_logic;
    function instr_is_csrrs  ( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return std_logic;

    --
    ------------------------------------------------------------------------------------
    --

    function instr_rs1_id( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return STD_LOGIC_VECTOR;
    function instr_rs2_id( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return STD_LOGIC_VECTOR;
    function instr_rd_id ( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return STD_LOGIC_VECTOR;
    function instr_csr_id( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return STD_LOGIC_VECTOR;

    --
    ------------------------------------------------------------------------------------
    --

    function repeat_bit(B: std_logic; N: natural) return std_logic_vector;

    function to_stdl(L: BOOLEAN) return std_ulogic;

    --
    ------------------------------------------------------------------------------------
    --

end package riscv_types;

--
--
-- Package Body Section
--
--

package body riscv_types is

    --
    ------------------------------------------------------------------------------------
    --

    function instr_is_system( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return std_logic is
    begin
        if INSTR(6 downto 2) = "11100" then
            return '1';
        else
            return '0';
        end if;
    end;

    function instr_is_ebreak( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return std_logic is
    begin
        if (INSTR(14 downto 12) = "000") and (instr_is_system(INSTR) = '1') then
            return '1';
        else
            return '0';
        end if;
    end;

    function instr_is_csrrs( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) ) return std_logic is
    begin
        if (INSTR(14 downto 12) = "010") and (instr_is_system(INSTR) = '1') then
            return '1';
        else
            return '0';
        end if;
    end;

    --
    ------------------------------------------------------------------------------------
    --

    function instr_rs1_id( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) )
        return STD_LOGIC_VECTOR is
    begin
        return INSTR(19 downto 15); 
    end;

    function instr_rs2_id( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) )
        return STD_LOGIC_VECTOR is
    begin
        return INSTR(24 downto 20);
    end;

    function instr_rd_id( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) )
        return STD_LOGIC_VECTOR is
    begin
        return INSTR(11 downto  7);
    end;

    function instr_csr_id( INSTR: STD_LOGIC_VECTOR(31 DOWNTO 0) )
        return STD_LOGIC_VECTOR is
    begin
        return INSTR(27) & INSTR(21);
    end;

    --
    ------------------------------------------------------------------------------------
    --

    function repeat_bit(B: std_logic; N: natural) return std_logic_vector is
        variable result: std_logic_vector(1 to N);
    begin
        for i in 1 to N loop
            result(i) := B;
        end loop;
        return result;
    end;  

    --
    ------------------------------------------------------------------------------------
    --

    function to_stdl(L: BOOLEAN) return std_ulogic is
    begin
        if L then
            return('1');
        else
            return('0');
        end if;
    end;


end package body riscv_types;
