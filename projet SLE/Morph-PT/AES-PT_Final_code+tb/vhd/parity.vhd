
library IEEE;
    use IEEE.std_logic_1164.all;

entity parity is port(
    data_in : in std_logic_vector(127 downto 0);
    parity_out : out std_logic_vector(15 downto 0)     );
    end parity;

architecture a_parity of parity is
begin
  i_for : for I in 0 to 15 generate
    parity_out( I ) <= data_in(8*I) xor data_in(8*I+1) xor data_in(8*I+2) xor data_in(8*I+3) 
                   xor data_in(8*I+4) xor data_in(8*I+5) xor data_in(8*I+6) xor data_in(8*I+7);
    end generate i_for;
  end a_parity;

