
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_misc.all;
    use IEEE.std_logic_arith.all;

library WORK;
package params is
		
  -- CONFIGURATION CONSTANTS
  constant C_INCLUDE_DECODING_LOGIC : boolean := false; -- Allow both enc and decryption
  constant C_CTRL_SIGNAL_SIZE       : integer := 1; -- 1 or 2
  -- constant C_ERR_SIGNAL_SIZE        : integer := 1; -- 1 or 2
  constant RESET_ACTIVE             : std_logic := '0';

  -- BUS PARAMETERS (SIZE, ...)
  -- constant DATA_SIZE  : integer := 32;
  -- constant MASK_SIZE  : integer :=  8;
  constant DATA_SIZE  : integer := 128;
  constant MASK_SIZE  : integer :=  32;
  constant COL_IDX_SZ : integer :=   2;
  constant BLK_IDX_SZ : integer :=   2; -- LOG2( NUMBER_OF_ROUNDS_INSTANCES )
  constant NUMBER_OF_ROUNDS_INSTANCES : integer := 4;
  constant MAX_ROUNDS : integer := NUMBER_OF_ROUNDS_INSTANCES-1; -- Security margin
  
  constant DATA_LO : integer := 0;
  constant DATA_HI : integer := DATA_LO + DATA_SIZE - 1; -- 127
  constant MASK_LO : integer := DATA_HI + 1; -- 128
  constant MASK_HI : integer := MASK_LO + MASK_SIZE - 1; -- 159
  constant CLID_LO  : integer := MASK_HI + 1; -- 160
  constant CLID_HI  : integer := CLID_LO + COL_IDX_SZ - 1; -- 161
  constant BLID_LO  : integer := CLID_HI + 1; -- 162
  constant BLID_HI  : integer := BLID_LO + BLK_IDX_SZ - 1; -- 163

  -- constant C_BROKEN : std_logic_vector( C_ERR_SIGNAL_SIZE-1 downto 0 ) := "1"; -- "10"; -- 

  type T_DFA_MODE is ( NONE, FULL_RED, PARTIAL_RED );
  subtype T_ENABLE is std_logic_vector( C_CTRL_SIGNAL_SIZE-1 downto 0 );
    constant C_ENABLED  : T_ENABLE := "1"; -- 01"; -- "
    constant C_DISABLED : T_ENABLE := "0"; -- 10"; -- "
  subtype T_ENCDEC is std_logic_vector( C_CTRL_SIGNAL_SIZE-1 downto 0 );
    constant C_DEC : T_ENCDEC := "1"; -- 01"; -- "
    constant C_ENC : T_ENCDEC := "0"; -- 10"; -- "
  subtype T_READY is std_logic_vector( C_CTRL_SIGNAL_SIZE-1 downto 0 );
    constant C_RDY : T_READY := "1"; -- 01"; -- "
    constant C_BSY : T_READY := "0"; -- 10"; -- "

  function ExpandMask( A : std_logic_vector( 31 downto 0 ) ) 
           return std_logic_vector;
  function count( A : std_logic_vector( 1 to 4 ) )
           return integer;
  function Enable2to1( A : T_ENABLE ) return std_logic;

  end params;


package body params is -- corresponding package body

  function ExpandMask( A : std_logic_vector( 31 downto 0 ) ) 
           return std_logic_vector is
  begin
    return( A( 31 downto 24 ) & A( 31 downto 24 ) & A( 31 downto 24 ) & A( 31 downto 24 ) & 
            A( 23 downto 16 ) & A( 23 downto 16 ) & A( 23 downto 16 ) & A( 23 downto 16 ) & 
            A( 15 downto  8 ) & A( 15 downto  8 ) & A( 15 downto  8 ) & A( 15 downto  8 ) & 
            A(  7 downto  0 ) & A(  7 downto  0 ) & A(  7 downto  0 ) & A(  7 downto  0 ) ); 
    end function ExpandMask;

  function count( A : std_logic_vector( 1 to 4 ) )
    return integer is
    variable a1, a2, a3, a4 : integer;
    variable res : integer range 0 to 4;
  begin
    if ( A(1)='0' ) then a1:=0; else a1:=1; end if;
    if ( A(2)='0' ) then a2:=0; else a2:=1; end if;
    if ( A(3)='0' ) then a3:=0; else a3:=1; end if;
    if ( A(4)='0' ) then a4:=0; else a4:=1; end if;
    res := a1 + a2 + a3 + a4;
    return ( res );
    end function count;

  function Enable2to1( A : T_ENABLE ) return std_logic is
  begin
    if ( A=C_ENABLED ) then return '1'; else return '0'; end if;
    end function Enable2to1;
  
  end package body params;
