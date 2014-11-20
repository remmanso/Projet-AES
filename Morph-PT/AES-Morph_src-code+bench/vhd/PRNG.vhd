--This software is provided 'as-is', without any express or implied warranty.
--In no event will the authors be held liable for any damages arising from the use of this software.

--Permission is granted to anyone to use this software for any purpose,
--excluding commercial applications, and to alter it and redistribute
--it freely except for commercial applications. 
--File:         trivium.vhd
--Author:       Richard Stern (rstern01@utopia.poly.edu)
--Organization: Polytechnic University
--------------------------------------------------------
--Description: Trivium encryption algorithm
--------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
library WORK;
  use WORK.params.all;

entity PRNG is
	generic( USE_GRAIN_RATHER_THAN_TRIVIUM : boolean := false );
	port(
		clk, rst : in std_logic;
		start : in std_logic;
		key, IV : in std_logic_vector( 79 downto 0 );
		valid :  out std_logic;
		rnd_out : out std_logic_vector( 47 downto 0 )
	);
	end PRNG;


architecture arch of PRNG is
	component trivium 
		port(	
			clk, rst	: in std_logic; 
			key	 : in std_logic_vector( 79 downto 0 );
			IV	 : in std_logic_vector( 79 downto 0 );
			o_vld	 : out std_logic;
			z	 : out std_logic);
		end component;
	component grain is
		port(	
			clk, rst, grst	: in std_logic; 
			key	 : in std_logic_vector( 79 downto 0 );
			IV	 : in std_logic_vector( 63 downto 0 );
			o_vld	 : out std_logic;
			z	 : out std_logic);
		end component;
	signal data, s_valid : std_logic;
	signal s_rnd_out : std_logic_vector( 47 downto 0 );
begin

	trivium_if : if ( not USE_GRAIN_RATHER_THAN_TRIVIUM ) generate 
		tr : trivium port map(
			clk => clk,  
			rst	=> start, 
			key	 => key, 
			IV	 => IV, 
			o_vld	 => s_valid,
			z	 => data
			); 
		end generate trivium_if;

	grain_if : if ( USE_GRAIN_RATHER_THAN_TRIVIUM ) generate 
		gr : grain port map(
			clk => clk,  
			rst	=> start, 
			grst => rst,
			key	 => key, 
			IV	 => IV( 63 downto 0 ), 
			o_vld	 => s_valid,
			z	 => data
			); 
		end generate grain_if;

	REG_PROC : process( clk )
  begin
		if ( clk'event and clk='1' ) then
			if ( start='1' or rst=RESET_ACTIVE ) then
				s_rnd_out <= ( others=>'0' );
				valid <= '0';
			else
				valid <= s_valid; --*
				if ( s_valid='1' ) then 
					s_rnd_out <= s_rnd_out( 46 downto 0 ) & data;
					-- valid <= '1';
					end if;
				end if;
			end if; -- clk
		end process REG_PROC;

	rnd_out <= s_rnd_out;
	-- valid <= s_valid;

	end arch;
