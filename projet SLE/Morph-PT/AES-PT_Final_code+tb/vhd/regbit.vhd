-- Library Declaration
library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

entity regbit is 
	port(
		clk, rst : in std_logic;
		din  : in std_logic;
		dout : out std_logic );
	end regbit;
	
architecture arch of regbit is
begin
	REG_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				dout <= '0';
			else 
				dout <= din;
				end if;
			end if;
		end process REG_PROC;
	end arch;