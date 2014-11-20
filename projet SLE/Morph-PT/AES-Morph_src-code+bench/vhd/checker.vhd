library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

entity checker is
  port(
    clk, rst : in std_logic; 
		enc_started : in std_logic; 
		bus_1, bus_2 : in std_logic_vector( BLID_HI downto 0 ); 
    enable_check : in T_ENABLE;
    alarm : out T_ENABLE
    );
  end checker;
  
architecture arch of checker is
  signal unmasked_bus_1, unmasked_bus_2 : std_logic_vector( DATA_HI downto DATA_LO ); 
  signal reordered_bus_1, reordered_bus_2 : std_logic_vector( DATA_HI downto DATA_LO ); 
	signal s_alarm : T_ENABLE;
begin

  unmasked_bus_1 <= bus_1( DATA_HI downto DATA_LO ) xor ExpandMask( bus_1( MASK_HI downto MASK_LO ) );
  unmasked_bus_2 <= bus_2( DATA_HI downto DATA_LO ) xor ExpandMask( bus_2( MASK_HI downto MASK_LO ) );
  
  reordered_bus_1 <= unmasked_bus_1                                                  when ( bus_1( CLID_HI downto CLID_LO )="00" ) 
                else unmasked_bus_1( 31 downto 0 ) & unmasked_bus_1( 127 downto 32 ) when ( bus_1( CLID_HI downto CLID_LO )="01" ) 
                else unmasked_bus_1( 63 downto 0 ) & unmasked_bus_1( 127 downto 64 ) when ( bus_1( CLID_HI downto CLID_LO )="10" ) 
                else unmasked_bus_1( 95 downto 0 ) & unmasked_bus_1( 127 downto 96 );                             
  reordered_bus_2 <= unmasked_bus_2                                                  when ( bus_2( CLID_HI downto CLID_LO )="00" ) 
                else unmasked_bus_2( 31 downto 0 ) & unmasked_bus_2( 127 downto 32 ) when ( bus_2( CLID_HI downto CLID_LO )="01" ) 
                else unmasked_bus_2( 63 downto 0 ) & unmasked_bus_2( 127 downto 64 ) when ( bus_2( CLID_HI downto CLID_LO )="10" ) 
                else unmasked_bus_2( 95 downto 0 ) & unmasked_bus_2( 127 downto 96 );                             

  CHK_PROC : process( clk )
	begin
		if ( clk'event and clk='1' ) then
			if ( rst=RESET_ACTIVE ) then 
				s_alarm <= C_DISABLED; 
			elsif ( enc_started='1' ) then
				s_alarm <= C_DISABLED; 
			elsif ( enable_check=C_ENABLED ) then 
				if ( reordered_bus_1/=reordered_bus_2 ) then 
					s_alarm <= C_ENABLED; 
					end if; -- reordered_bus_1/=reordered_bus_2
				end if; --  enc_started, enable_check
			end if; -- clk
		end process CHK_PROC;
		
	alarm <= s_alarm;
	
	end architecture arch;
