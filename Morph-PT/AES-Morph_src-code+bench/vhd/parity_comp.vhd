library IEEE;
	use IEEE.std_logic_1164.all;
	use IEEE.numeric_std.all;
	
library WORK;
	use WORK.params.all;

entity parity_comp is port(
	clk, rst : in std_logic; 
	inp0, inp1 : in std_logic_vector(15 downto 0);
	lin_mask : in std_logic_vector( MASK_SIZE-1 downto 0 );
	enable_comp : in T_ENABLE;
	alarm : out T_ENABLE;
end parity_comp;

architecture arch_parity_comp of parity is
	signal s_inp0, s_inp1 : std_logic_vector(15 downto 0);
	signal s_alarm : T_ENABLE;
begin

	OLD_MASK_PROC : process( clk ) 
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				old_mask_reg <= ( others=>'0' );
			elsif ( enable_H_inputs = C_ENABLED ) then 
				if ( realign = C_ENABLED ) then 
					old_mask_reg <= old_mask_reg;
				else
					old_mask_reg <= data_in( MASK_HI downto MASK_LO );
					end if;
				end if; -- rst, enable_H_inputs
			end if; -- clk
		end process OLD_MASK_PROC;
	NEW_MASK_PROC : process( clk ) 
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then
				new_mask_reg <= ( others=>'0' );
			elsif ( set_new_mask = C_ENABLED ) then 
				new_mask_reg <= lin_mask;
			elsif ( enable_H_inputs = C_ENABLED ) then 
				new_mask_reg <= data_in( MASK_HI downto MASK_LO );
				end if; -- rst, enable_H_inputs
			end if; -- clk
		end process NEW_MASK_PROC;

	COMP_PROC : process ( clk )
	begin 
		if ( clk'event and clk='1' ) then 
			if (rst=RESET_ACTIVE) then
				s_alarm <= C_DISABLED;
			elsif ( enc_started=C_ENABLED ) then
				if ( s_inp0/=s_inp1 ) then
					s_alarm <= C_ENABLED;
				end if; -- s_inp0/=s_inp1
			end if; -- reset & enc_started
		end if; -- clock
	end process COMP_PROC;

	alarm <= s_alarm;
end architecture a_parity_comp;