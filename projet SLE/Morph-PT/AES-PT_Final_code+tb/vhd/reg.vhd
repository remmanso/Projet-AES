-- Library Declaration
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity reg is 
	generic( SIZE : integer := 8 );
	port(
		clk, rst : in std_logic;
		din  : in std_logic_vector( SIZE-1 downto 0 );
		dout : out std_logic_vector( SIZE-1 downto 0 ) );
	end reg;
	
architecture arch of reg is
begin
	REG_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				dout <= ( others=>'0' );
			else 
				dout <= din;
				end if;
			end if;
		end process REG_PROC;
	end arch;