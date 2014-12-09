-- Library Declaration
library IEEE;
use IEEE.std_logic_1164.all;

-- Component Declaration
entity PreMcRot_B is
  generic( G_ROW : integer range 0 to 3 ); 
  port ( 
    in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
    pin_0, pin_1, pin_2, pin_3 : in std_logic;
    out_0, out_1, out_2, out_3 : out std_logic_vector (7 downto 0) ) ;
    pout_0, pout_1, pout_2, pout_3 : std_logic;
  end PreMcRot_B;

-- Architecture of the Component
architecture a_PreMcRot of PreMcRot_B is
begin
  i0 : if ( G_ROW=0 ) generate
    out_0 <= in_0; 
    out_1 <= in_1; 
    out_2 <= in_2; 
    out_3 <= in_3;
    pout_0 <= pin_0; 
    pout_1 <= pin_1; 
    pout_2 <= pin_2; 
    pout_3 <= pin_3; 
    end generate; -- 0
  i1 : if ( G_ROW=1 ) generate
    out_0 <= in_1; 
    out_1 <= in_2; 
    out_2 <= in_3; 
    out_3 <= in_0;
    pout_0 <= pin_1; 
    pout_1 <= pin_2; 
    pout_2 <= pin_3; 
    pout_3 <= pin_0; 
    end generate; -- 1
  i2 : if ( G_ROW=2 ) generate
    out_0 <= in_2; 
    out_1 <= in_3; 
    out_2 <= in_0; 
    out_3 <= in_1;
    pout_0 <= pin_2; 
    pout_1 <= pin_3; 
    pout_2 <= pin_0; 
    pout_3 <= pin_1; 
    end generate; -- 2
  i3 : if ( G_ROW=3 ) generate
    out_0 <= in_3; 
    out_1 <= in_0; 
    out_2 <= in_1; 
    out_3 <= in_2;
    pout_0 <= pin_3; 
    pout_1 <= pin_0; 
    pout_2 <= pin_1; 
    pout_3 <= pin_2; 
    end generate; -- 3
  end a_PreMcRot;