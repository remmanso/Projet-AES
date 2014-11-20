library IEEE;
    use IEEE.std_logic_1164.all;
library WORK;
    use WORK.aes_pt_params.all;

-- Component Declaration
entity trigger is port (
    switch, clock, reset : in std_logic;
    value : out std_logic );
    end trigger;


-- Architecture of the Component
architecture arch of trigger is
begin
    process( clock )
    begin
	   if ( clock'event and clock='1' ) then
        if ( reset=RESET_ACTIVE ) then
            value <= '0';
        elsif ( switch='1' ) then
            value <= '1';
            end if;
        end if; -- clock
		end process;
    end arch;
