------------------------------------------------------
------------------------------------------------------

library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

entity get123 is 
	port (
		d_in : in std_logic_vector( 1 to 4 ); 
		first, second, third : out std_logic_vector( 1 to 4 )
		); 
	end get123;


-- Architecture of the Component
architecture arch of get123 is
	signal s1, s2, s3 : std_logic_vector( 1 to 4 );
begin
	S1_PROC : process( d_in )
	begin
		case ( d_in ) is
			when "0001" => s1 <= "0001";
			when "0010" => s1 <= "0010";
			when "0011" => s1 <= "0010";
			when "0100" => s1 <= "0100";
			when "0101" => s1 <= "0100";
			when "0110" => s1 <= "0100";
			when "0111" => s1 <= "0100";
			when "1000" => s1 <= "1000";
			when "1001" => s1 <= "1000";
			when "1010" => s1 <= "1000";
			when "1011" => s1 <= "1000";
			when "1100" => s1 <= "1000";
			when "1101" => s1 <= "1000";
			when "1110" => s1 <= "1000";
			when "1111" => s1 <= "1000";
			when others => s1 <= "0000"; -- Don't cares ?!
			end case;
		end process S1_PROC;

	S2_PROC : process( d_in )
	begin
		case ( d_in ) is
			when "0011" => s2 <= "0001";
			when "0101" => s2 <= "0001";
			when "0110" => s2 <= "0010";
			when "0111" => s2 <= "0010";
			when "1001" => s2 <= "0001";
			when "1010" => s2 <= "0010";
			when "1011" => s2 <= "0010";
			when "1100" => s2 <= "0100";
			when "1101" => s2 <= "0100";
			when "1110" => s2 <= "0100";
			when "1111" => s2 <= "0100";
			when others => s2 <= "0000"; -- Don't cares ?!
			end case;
		end process S2_PROC;

	S3_PROC : process( d_in )
	begin
		case ( d_in ) is
			when "0111" => s3 <= "0001";
			when "1011" => s3 <= "0001";
			when "1101" => s3 <= "0001";
			when "1110" => s3 <= "0010";
			when others => s3 <= "0000"; -- Don't cares ?!
			end case;
		end process S3_PROC;

	first  <= s1;
	second <= s2;
	third  <= s3;
	end architecture arch;
