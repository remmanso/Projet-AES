-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

-- Entity Declaration
entity bus_map is 
	port (
		prev_bus_config : in std_logic_vector( 1 to 4 );
		transf_matrix : in std_logic_vector( 15 downto 0 );
		next_bus_config : out std_logic_vector( 1 to 4 )
		);
  end bus_map;

-- Architecture of the Component
architecture arch of bus_map is
begin
	next_bus_config( 1 ) <= ( transf_matrix(15) and prev_bus_config( 1 ) ) or
													( transf_matrix(14) and prev_bus_config( 2 ) ) or
													( transf_matrix(13) and prev_bus_config( 3 ) ) or
													( transf_matrix(12) and prev_bus_config( 4 ) );
	next_bus_config( 2 ) <= ( transf_matrix(11) and prev_bus_config( 1 ) ) or
													( transf_matrix(10) and prev_bus_config( 2 ) ) or
													( transf_matrix( 9) and prev_bus_config( 3 ) ) or
													( transf_matrix( 8) and prev_bus_config( 4 ) );
	next_bus_config( 3 ) <= ( transf_matrix( 7) and prev_bus_config( 1 ) ) or
													( transf_matrix( 6) and prev_bus_config( 2 ) ) or
													( transf_matrix( 5) and prev_bus_config( 3 ) ) or
													( transf_matrix( 4) and prev_bus_config( 4 ) );
	next_bus_config( 4 ) <= ( transf_matrix( 3) and prev_bus_config( 1 ) ) or
													( transf_matrix( 2) and prev_bus_config( 2 ) ) or
													( transf_matrix( 1) and prev_bus_config( 3 ) ) or
													( transf_matrix( 0) and prev_bus_config( 4 ) );
	end arch;
