-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity datacell is port (
  -- A = Leftmost column, B = Middleleft column
  clock, reset : in std_logic; 
  in_H, in_V : in std_logic_vector (7 downto 0);
  enable_H_in : in T_ENABLE;
  b_out : out std_logic_vector (7 downto 0) );
  end datacell;

-- Architecture of the Component
architecture a_dc of datacell is
  component reg_B
    generic( G_SIZE : integer := 8 ); 
    port (
      din : in std_logic_vector (G_SIZE-1 downto 0);
      dout : out std_logic_vector (G_SIZE-1 downto 0);
      clock, reset : in std_logic );
    end component ;
  signal actual_in : std_logic_vector ( 7 downto 0 );
begin
  actual_in <= in_H when ( enable_H_in=C_ENABLED ) else in_V;
  I_REG : reg_B generic map( 8 ) 
              port map( actual_in, b_out,
                        clock, reset );
 
  end a_dc;
