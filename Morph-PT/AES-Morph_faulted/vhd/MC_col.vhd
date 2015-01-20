-- Library Declaration
library IEEE;
  use IEEE.std_logic_1164.all;
library WORK;
  use WORK.params.all;

-- Component Declaration
entity MC_col is port (
  din : in std_logic_vector (31 downto 0);
  ctrl_dec : in T_ENCDEC;
  dout : out std_logic_vector (31 downto 0) ) ;
  end MC_col;

-- Architecture of the Component
architecture a_MC_col of MC_col is
  component PreMcRot_B 
    generic( G_ROW : integer range 0 to 3 ); 
    port ( 
      in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
      out_0, out_1, out_2, out_3 : out std_logic_vector (7 downto 0) ) ;
    end component;
  component mixcolumn0 is port (
    in_0, in_1, in_2, in_3 : in std_logic_vector (7 downto 0);
    ctrl_dec : in T_ENCDEC;
    b_out : out std_logic_vector (7 downto 0) );
    end component;
  signal Value_PostRot_0, Value_PostRot_1, Value_PostRot_2, Value_PostRot_3 : std_logic_vector (31 downto 0);
  signal MC_out : std_logic_vector (31 downto 0);
begin
  Rot0: PreMcRot_B generic map( 0 ) 
        port map( din( 31 downto 24 ), din( 23 downto 16 ),
                  din( 15 downto 8 ), din( 7 downto 0 ),
                  Value_PostRot_0( 31 downto 24 ), Value_PostRot_0( 23 downto 16 ),
                  Value_PostRot_0( 15 downto 8 ), Value_PostRot_0( 7 downto 0 ) );
  Rot1: PreMcRot_B generic map( 1 ) 
        port map( din( 31 downto 24 ), din( 23 downto 16 ),
                  din( 15 downto 8 ), din( 7 downto 0 ),
                  Value_PostRot_1( 31 downto 24 ), Value_PostRot_1( 23 downto 16 ),
                  Value_PostRot_1( 15 downto 8 ), Value_PostRot_1( 7 downto 0 ) );
  Rot2: PreMcRot_B generic map( 2 ) 
        port map( din( 31 downto 24 ), din( 23 downto 16 ),
                  din( 15 downto 8 ), din( 7 downto 0 ),
                  Value_PostRot_2( 31 downto 24 ), Value_PostRot_2( 23 downto 16 ),
                  Value_PostRot_2( 15 downto 8 ), Value_PostRot_2( 7 downto 0 ) );
  Rot3: PreMcRot_B generic map( 3 ) 
        port map( din( 31 downto 24 ), din( 23 downto 16 ),
                  din( 15 downto 8 ), din( 7 downto 0 ),
                  Value_PostRot_3( 31 downto 24 ), Value_PostRot_3( 23 downto 16 ),
                  Value_PostRot_3( 15 downto 8 ), Value_PostRot_3( 7 downto 0 ) );
                  
  MC0 : mixcolumn0 
        port map( Value_PostRot_0( 31 downto 24 ), Value_PostRot_0( 23 downto 16 ),
                  Value_PostRot_0( 15 downto 8 ), Value_PostRot_0( 7 downto 0 ),
                  ctrl_dec,  MC_out( 31 downto 24 ) );
  MC1 : mixcolumn0 
        port map( Value_PostRot_1( 31 downto 24 ), Value_PostRot_1( 23 downto 16 ),
                  Value_PostRot_1( 15 downto 8 ), Value_PostRot_1( 7 downto 0 ),
                  ctrl_dec, MC_out( 23 downto 16 ) );
  MC2 : mixcolumn0 
        port map( Value_PostRot_2( 31 downto 24 ), Value_PostRot_2( 23 downto 16 ),
                  Value_PostRot_2( 15 downto 8 ), Value_PostRot_2( 7 downto 0 ),
                  ctrl_dec, MC_out( 15 downto 8 ) );
  MC3 : mixcolumn0 
        port map( Value_PostRot_3( 31 downto 24 ), Value_PostRot_3( 23 downto 16 ),
                  Value_PostRot_3( 15 downto 8 ), Value_PostRot_3( 7 downto 0 ),
                  ctrl_dec, MC_out( 7 downto 0 ) );
                  
  dout <= MC_out;
  end a_MC_col;
