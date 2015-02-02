library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
library WORK;
  use WORK.params.all;


entity reg_en is
  generic( n : integer := 128 );
  port( 
    clk, rst 	: in STD_LOGIC;
    din	: in STD_LOGIC_VECTOR (n-1 downto 0);
    en: in STD_LOGIC;
    dout	: out STD_LOGIC_VECTOR (n-1 downto 0) );
  end reg_en;

architecture arch of reg_en is
  signal s_data : std_logic_vector( n-1 downto 0 );
begin
  REG_PROC : process( clk )
  begin
    if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
        s_data <= ( others=>'0' );
		  elsif ( en='1' ) then
        s_data <= din;
        end if; -- rst, enabled
      end if; -- clk
    end process REG_PROC;
  dout <= s_data;
  end arch;
