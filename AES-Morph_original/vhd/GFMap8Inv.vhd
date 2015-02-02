
-- Library Declaration
library IEEE;
use IEEE.std_logic_1164.all;


-- Component Declaration
entity gfmap8inv is port (
   -- ah -> High Data Input (4 std_logic)
   -- al -> Low Data Input (4 std_logic)
   -- a -> Data Output (8 std_logic)
  ah, al : in std_logic_vector (3 downto 0);
  a : out std_logic_vector (7 downto 0)   );
  end gfmap8inv;

-- Architecture of the Component
architecture a_gfmap8inv of gfmap8inv is
begin
   -- Inverse Mapping Process
	a(7) <= ah(3) xor al(3) xor al(1);
	a(6) <= ah(1) xor al(2) xor al(1);
	a(5) <= al(3) xor al(1);
	a(4) <= ah(2) xor ah(1) xor ah(0) xor al(3) xor al(2);
	a(3) <= ah(3) xor ah(2) xor ah(1) xor al(2);
	a(2) <= ah(3) xor ah(2) xor al(2);
	a(1) <= ah(3) xor ah(0);
	a(0) <= ah(2) xor ah(1) xor al(2) xor al(0);
  end a_gfmap8inv;
