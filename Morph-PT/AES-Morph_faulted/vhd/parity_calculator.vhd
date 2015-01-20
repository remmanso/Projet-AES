-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity parity_calculator is port (
  data_in : in std_logic_vector( 7 downto 0 ); 
  data_out : out std_logic
  );
  end parity_calculator;

-- Architecture of the Component
Architecture a_parity_calculator of parity_calculator is
	begin
	  data_out <= data_in(0) xor data_in(1) xor data_in(2) xor data_in(3) 
	  xor data_in(4) xor data_in(5) xor data_in(6) xor data_in(7);
end a_parity_calculator;