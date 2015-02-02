-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity reg_B is
  generic( G_SIZE : integer := 8 ); 
  port (
		clock, reset : in std_logic;
    din : in std_logic_vector (G_SIZE-1 downto 0);
    dout : out std_logic_vector (G_SIZE-1 downto 0)
    );
  end reg_B;

-- Architecture of the Component
architecture a_reg of reg_B is
  signal main : std_logic_vector (G_SIZE-1 downto 0);
begin
  process( clock, reset )
  begin
    if ( clock'event and clock='1' ) then
      if ( reset=RESET_ACTIVE ) then
      	main <= ( others=>'0' ); 
    	else 
				main <= din;
      	end if; -- reset, 
			end if; -- clock
    end process;
  dout <= main;
  end a_reg;
